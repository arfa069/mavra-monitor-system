import { useCallback, useMemo, useState } from "react";
import {
  App,
  Button,
  DatePicker,
  Form,
  Input,
  Modal,
  Select,
  Space,
  Table,
  Tag,
  Typography,
  Upload,
} from "antd";
import type { ColumnsType } from "antd/es/table";
import {
  EditOutlined,
  FileTextOutlined,
  PlusOutlined,
  UploadOutlined,
} from "@ant-design/icons";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import dayjs from "dayjs";
import { formatApiError } from "@/shared/api/client";
import { blogApi } from "./api/blog";
import RichTextEditor from "./components/RichTextEditor";
import type {
  BlogCategory,
  BlogPost,
  BlogPostListItem,
  BlogPostPayload,
  BlogPostStatus,
  BlogTag,
} from "./types";

const { Text, Title } = Typography;

const STATUS_LABELS: Record<BlogPostStatus, string> = {
  draft: "Draft",
  scheduled: "Scheduled",
  published: "Published",
  archived: "Archived",
};

const STATUS_COLORS: Record<BlogPostStatus, string> = {
  draft: "default",
  scheduled: "processing",
  published: "success",
  archived: "warning",
};

interface EditorValue {
  html: string;
  json: Record<string, unknown>;
}

const EMPTY_EDITOR: EditorValue = {
  html: "<p></p>",
  json: { type: "doc", content: [{ type: "paragraph" }] },
};

export function BlogAdminPage() {
  const message = App.useApp().message;
  const queryClient = useQueryClient();
  const [form] = Form.useForm();
  const [saving, setSaving] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingPost, setEditingPost] = useState<BlogPost | null>(null);
  const [statusFilter, setStatusFilter] = useState<BlogPostStatus | undefined>();
  const [keyword, setKeyword] = useState("");
  const [editorValue, setEditorValue] = useState<EditorValue>(EMPTY_EDITOR);

  const postsQuery = useQuery({
    queryKey: ["blog-admin-posts", keyword, statusFilter],
    queryFn: async () => {
      const response = await blogApi.listAdminPosts({
        page: 1,
        size: 20,
        keyword: keyword || undefined,
        status: statusFilter,
      });
      return response.data.items;
    },
  });

  const taxonomyQuery = useQuery({
    queryKey: ["blog-taxonomy"],
    queryFn: async () => {
      const [categoryResponse, tagResponse] = await Promise.all([
        blogApi.listCategories(),
        blogApi.listTags(),
      ]);
      return {
        categories: categoryResponse.data,
        tags: tagResponse.data,
      };
    },
  });

  const posts: BlogPostListItem[] = postsQuery.data ?? [];
  const categories: BlogCategory[] = taxonomyQuery.data?.categories ?? [];
  const tags: BlogTag[] = taxonomyQuery.data?.tags ?? [];

  const openNewPost = () => {
    setEditingPost(null);
    setEditorValue(EMPTY_EDITOR);
    form.resetFields();
    form.setFieldsValue({ status: "draft" });
    setModalOpen(true);
  };

  const openEditPost = useCallback(async (postId: number) => {
    try {
      const response = await blogApi.getAdminPost(postId);
      const post = response.data;
      setEditingPost(post);
      setEditorValue({
        html: post.content_html || "<p></p>",
        json: post.content_json || EMPTY_EDITOR.json,
      });
      form.setFieldsValue({
        title: post.title,
        slug: post.slug,
        excerpt: post.excerpt,
        status: post.status,
        category_name: post.category?.name,
        tag_names: post.tags.map((tag) => tag.name),
        cover_url: post.cover_url,
        seo_title: post.seo_title,
        seo_description: post.seo_description,
        canonical_url: post.canonical_url,
        og_image_url: post.og_image_url,
        published_at: post.published_at ? dayjs(post.published_at) : undefined,
      });
      setModalOpen(true);
    } catch (error) {
      message.error(formatApiError(error, "Failed to open blog post"));
    }
  }, [form, message]);

  const savePost = async () => {
    try {
      const values = await form.validateFields();
      if (values.status === "scheduled" && !values.published_at) {
        message.error("Scheduled posts need a publish time");
        return;
      }
      setSaving(true);
      const payload: BlogPostPayload = {
        title: values.title,
        slug: values.slug || null,
        excerpt: values.excerpt || null,
        content_json: editorValue.json,
        content_html: editorValue.html,
        status: values.status,
        category_name: values.category_name || null,
        tag_names: values.tag_names || [],
        cover_url: values.cover_url || null,
        seo_title: values.seo_title || null,
        seo_description: values.seo_description || null,
        canonical_url: values.canonical_url || null,
        og_image_url: values.og_image_url || null,
        published_at: values.published_at
          ? values.published_at.toISOString()
          : null,
      };
      if (editingPost) {
        await blogApi.updatePost(editingPost.id, payload);
        message.success("Blog post updated");
      } else {
        await blogApi.createPost(payload);
        message.success("Blog post created");
      }
      setModalOpen(false);
      void queryClient.invalidateQueries({ queryKey: ["blog-admin-posts"] });
      void queryClient.invalidateQueries({ queryKey: ["blog-taxonomy"] });
    } catch (error) {
      message.error(formatApiError(error, "Failed to save blog post"));
    } finally {
      setSaving(false);
    }
  };

  const uploadCover = async (file: File) => {
    try {
      const response = await blogApi.uploadMedia(file);
      form.setFieldValue("cover_url", response.data.public_url);
      message.success("Image uploaded");
    } catch (error) {
      message.error(formatApiError(error, "Upload failed"));
    }
    return false;
  };

  const columns: ColumnsType<BlogPostListItem> = useMemo(
    () => [
      {
        title: "Title",
        dataIndex: "title",
        render: (_value, record) => (
          <Space direction="vertical" size={2}>
            <Text strong>{record.title}</Text>
            <Text type="secondary">/{record.slug}</Text>
          </Space>
        ),
      },
      {
        title: "Status",
        dataIndex: "status",
        width: 130,
        render: (status: BlogPostStatus) => (
          <Tag color={STATUS_COLORS[status]}>{STATUS_LABELS[status]}</Tag>
        ),
      },
      {
        title: "Taxonomy",
        key: "taxonomy",
        render: (_value, record) => (
          <Space wrap size={[4, 4]}>
            {record.category ? <Tag>{record.category.name}</Tag> : null}
            {record.tags.map((tag) => (
              <Tag key={tag.id}>{tag.name}</Tag>
            ))}
          </Space>
        ),
      },
      {
        title: "Published",
        dataIndex: "published_at",
        width: 170,
        render: (value?: string | null) =>
          value ? dayjs(value).format("YYYY-MM-DD HH:mm") : "Not set",
      },
      {
        title: "Actions",
        key: "actions",
        width: 120,
        render: (_value, record) => (
          <Button
            icon={<EditOutlined />}
            onClick={() => void openEditPost(record.id)}
          >
            Edit
          </Button>
        ),
      },
    ],
    [openEditPost],
  );

  return (
    <div>
      <div className="page-header bg-coral">
        <div className="page-header-inner">
          <div>
            <Text type="secondary">Public writing</Text>
            <Title level={2} style={{ margin: 0 }}>
              Blog Studio
            </Title>
          </div>
          <Button type="primary" icon={<PlusOutlined />} onClick={openNewPost}>
            New post
          </Button>
        </div>
      </div>

      <Space style={{ marginBottom: 16 }} wrap>
        <Input.Search
          allowClear
          placeholder="Search posts"
          style={{ width: 260 }}
          onSearch={(value) => setKeyword(value)}
        />
        <Select
          allowClear
          placeholder="Status"
          style={{ width: 180 }}
          value={statusFilter}
          onChange={(value) => setStatusFilter(value as BlogPostStatus | undefined)}
          options={Object.entries(STATUS_LABELS).map(([value, label]) => ({
            value,
            label,
          }))}
        />
      </Space>

      <Table
        rowKey="id"
        loading={postsQuery.isFetching}
        columns={columns}
        dataSource={posts}
        pagination={false}
      />

      <Modal
        title={
          <Space>
            <FileTextOutlined />
            {editingPost ? "Edit blog post" : "New blog post"}
          </Space>
        }
        open={modalOpen}
        width={980}
        onCancel={() => setModalOpen(false)}
        onOk={() => void savePost()}
        okText={editingPost ? "Save" : "Create"}
        confirmLoading={saving}
        destroyOnHidden
      >
        <Form form={form} layout="vertical" initialValues={{ status: "draft" }}>
          <Space align="start" style={{ width: "100%" }} size={16}>
            <Form.Item
              name="title"
              label="Title"
              rules={[{ required: true, message: "Title is required" }]}
              style={{ flex: 1, minWidth: 280 }}
            >
              <Input placeholder="Post title" />
            </Form.Item>
            <Form.Item name="status" label="Status" style={{ width: 180 }}>
              <Select
                options={Object.entries(STATUS_LABELS).map(([value, label]) => ({
                  value,
                  label,
                }))}
              />
            </Form.Item>
          </Space>
          <Space align="start" style={{ width: "100%" }} size={16}>
            <Form.Item name="slug" label="Slug" style={{ flex: 1 }}>
              <Input placeholder="auto-generated-from-title" />
            </Form.Item>
            <Form.Item name="published_at" label="Publish time" style={{ width: 240 }}>
              <DatePicker showTime style={{ width: "100%" }} />
            </Form.Item>
          </Space>
          <Form.Item name="excerpt" label="Excerpt">
            <Input.TextArea rows={2} placeholder="Short public summary" />
          </Form.Item>
          <Space align="start" style={{ width: "100%" }} size={16}>
            <Form.Item name="category_name" label="Category" style={{ flex: 1 }}>
              <Select
                allowClear
                showSearch
                placeholder="Category"
                options={categories.map((category) => ({
                  value: category.name,
                  label: category.name,
                }))}
              />
            </Form.Item>
            <Form.Item name="tag_names" label="Tags" style={{ flex: 1 }}>
              <Select
                mode="tags"
                placeholder="Tags"
                options={tags.map((tag) => ({ value: tag.name, label: tag.name }))}
              />
            </Form.Item>
          </Space>
          <Form.Item name="cover_url" label="Cover image">
            <Input
              addonAfter={
                <Upload
                  showUploadList={false}
                  beforeUpload={(file) => {
                    void uploadCover(file);
                    return false;
                  }}
                >
                  <Button icon={<UploadOutlined />}>Upload</Button>
                </Upload>
              }
              placeholder="/blog-media/cover.webp"
            />
          </Form.Item>
          <Form.Item label="Body">
            <RichTextEditor value={editorValue} onChange={setEditorValue} />
          </Form.Item>
          <Space align="start" style={{ width: "100%" }} size={16}>
            <Form.Item name="seo_title" label="SEO title" style={{ flex: 1 }}>
              <Input />
            </Form.Item>
            <Form.Item
              name="seo_description"
              label="SEO description"
              style={{ flex: 1 }}
            >
              <Input />
            </Form.Item>
          </Space>
          <Space align="start" style={{ width: "100%" }} size={16}>
            <Form.Item name="canonical_url" label="Canonical URL" style={{ flex: 1 }}>
              <Input />
            </Form.Item>
            <Form.Item name="og_image_url" label="Open Graph image" style={{ flex: 1 }}>
              <Input />
            </Form.Item>
          </Space>
        </Form>
      </Modal>
    </div>
  );
}
