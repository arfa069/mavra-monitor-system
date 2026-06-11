import { useEffect } from "react";
import { Button, Space, Tooltip } from "antd";
import {
  BoldOutlined,
  ItalicOutlined,
  LinkOutlined,
  PictureOutlined,
  OrderedListOutlined,
  UnorderedListOutlined,
} from "@ant-design/icons";
import Image from "@tiptap/extension-image";
import Link from "@tiptap/extension-link";
import Placeholder from "@tiptap/extension-placeholder";
import { EditorContent, useEditor } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";

interface RichTextValue {
  html: string;
  json: Record<string, unknown>;
}

interface RichTextEditorProps {
  value: RichTextValue;
  onChange: (value: RichTextValue) => void;
}

export default function RichTextEditor({ value, onChange }: RichTextEditorProps) {
  const editor = useEditor({
    extensions: [
      StarterKit,
      Link.configure({
        openOnClick: false,
        autolink: true,
        HTMLAttributes: { rel: "noopener noreferrer", target: "_blank" },
      }),
      Image,
      Placeholder.configure({ placeholder: "Write the post..." }),
    ],
    content: value.html || "<p></p>",
    editorProps: {
      attributes: {
        class: "blog-rich-editor",
        "aria-label": "Blog post body",
      },
    },
    onUpdate: ({ editor }) => {
      onChange({
        html: editor.getHTML(),
        json: editor.getJSON() as Record<string, unknown>,
      });
    },
  });

  useEffect(() => {
    if (!editor) return;
    const current = editor.getHTML();
    if ((value.html || "<p></p>") !== current) {
      editor.commands.setContent(value.html || "<p></p>", { emitUpdate: false });
    }
  }, [editor, value.html]);

  const setLink = () => {
    if (!editor) return;
    const previousUrl = editor.getAttributes("link").href as string | undefined;
    const url = window.prompt("Link URL", previousUrl || "https://");
    if (url === null) return;
    if (!url.trim()) {
      editor.chain().focus().extendMarkRange("link").unsetLink().run();
      return;
    }
    editor.chain().focus().extendMarkRange("link").setLink({ href: url }).run();
  };

  const addImage = () => {
    if (!editor) return;
    const url = window.prompt("Image URL", "/blog-media/");
    if (!url?.trim()) return;
    editor.chain().focus().setImage({ src: url }).run();
  };

  const buttonStyle = { minWidth: 36 };

  return (
    <div
      style={{
        border: "1px solid var(--color-border)",
        borderRadius: "var(--radius-md)",
        background: "var(--color-surface-raised)",
        overflow: "hidden",
      }}
    >
      <Space
        wrap
        style={{
          padding: 8,
          borderBottom: "1px solid var(--color-border)",
          background: "var(--color-surface)",
        }}
      >
        <Tooltip title="Bold">
          <Button
            aria-label="Bold"
            icon={<BoldOutlined />}
            style={buttonStyle}
            onClick={() => editor?.chain().focus().toggleBold().run()}
          />
        </Tooltip>
        <Tooltip title="Italic">
          <Button
            aria-label="Italic"
            icon={<ItalicOutlined />}
            style={buttonStyle}
            onClick={() => editor?.chain().focus().toggleItalic().run()}
          />
        </Tooltip>
        <Tooltip title="Bullet list">
          <Button
            aria-label="Bullet list"
            icon={<UnorderedListOutlined />}
            style={buttonStyle}
            onClick={() => editor?.chain().focus().toggleBulletList().run()}
          />
        </Tooltip>
        <Tooltip title="Numbered list">
          <Button
            aria-label="Numbered list"
            icon={<OrderedListOutlined />}
            style={buttonStyle}
            onClick={() => editor?.chain().focus().toggleOrderedList().run()}
          />
        </Tooltip>
        <Tooltip title="Link">
          <Button
            aria-label="Link"
            icon={<LinkOutlined />}
            style={buttonStyle}
            onClick={setLink}
          />
        </Tooltip>
        <Tooltip title="Image URL">
          <Button
            aria-label="Image URL"
            icon={<PictureOutlined />}
            style={buttonStyle}
            onClick={addImage}
          />
        </Tooltip>
      </Space>
      <EditorContent editor={editor} />
      <style>{`
        .blog-rich-editor {
          min-height: 260px;
          padding: 16px;
          outline: none;
          color: var(--color-ink);
          font-family: var(--font-body);
          line-height: 1.65;
        }
        .blog-rich-editor p {
          margin: 0 0 12px;
        }
        .blog-rich-editor img {
          max-width: 100%;
          border-radius: var(--radius-md);
        }
      `}</style>
    </div>
  );
}
