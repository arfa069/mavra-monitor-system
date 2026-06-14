import {
  productsListProducts,
  productsGetProduct,
  productsCreateProduct,
  productsUpdateProduct,
  productsDeleteProduct,
  productsBatchCreateProducts,
  productsBatchDeleteProducts,
  productsBatchUpdateProducts,
  productsGetProductHistory,
  productsListProductCronConfigs,
  productsCreateProductCronConfig,
  productsUpdateProductCronConfig,
  productsDeleteProductCronConfig,
  productsGetProductCronSchedules,
  productsListProductProfileBindings,
  productsUpsertProductProfileBinding,
  productsDeleteProductProfileBinding,
} from "@/shared/api/generated/products/products";
import type {
  ProductCreate,
  ProductUpdate,
  ProductBatchCreate,
  ProductBatchCreateItem,
  ProductBatchDelete,
  ProductBatchUpdate,
  ProductPlatformCronCreate,
  ProductPlatformCronUpdate,
  ProductPlatformProfileBindingUpdate,
  ProductsListProductsParams,
} from "@/shared/api/generated/models";

export const productsApi = {
  list: (params: {
    platform?: string;
    active?: boolean;
    keyword?: string;
    page?: number;
    size?: number;
  }) => productsListProducts(params as ProductsListProductsParams),

  get: (id: number) => productsGetProduct(id),

  create: (data: ProductCreate) => productsCreateProduct(data),

  update: (id: number, data: ProductUpdate) => productsUpdateProduct(id, data),

  delete: (id: number) => productsDeleteProduct(id),

  batchCreate: (items: ProductBatchCreateItem[]) =>
    productsBatchCreateProducts({ items } as ProductBatchCreate),

  batchDelete: (ids: number[]) =>
    productsBatchDeleteProducts({ ids } as ProductBatchDelete),

  batchUpdate: (ids: number[], active?: boolean) =>
    productsBatchUpdateProducts({ ids, active } as ProductBatchUpdate),

  history: (id: number, days = 30, limit = 100) =>
    productsGetProductHistory(id, { days, limit }).then((res) =>
      res.map((item) => ({
        ...item,
        price: Number(item.price),
      })),
    ),

  // Per-platform cron configs
  getCronConfigs: () => productsListProductCronConfigs(),

  createCronConfig: (data: ProductPlatformCronCreate) =>
    productsCreateProductCronConfig(data),

  updateCronConfig: (platform: string, data: ProductPlatformCronUpdate) =>
    productsUpdateProductCronConfig(platform, data),

  deleteCronConfig: (platform: string) =>
    productsDeleteProductCronConfig(platform),

  getCronSchedules: () => productsGetProductCronSchedules(),

  getProfileBindings: () => productsListProductProfileBindings(),

  updateProfileBinding: (
    platform: string,
    data: ProductPlatformProfileBindingUpdate,
  ) => productsUpsertProductProfileBinding(platform, data),

  deleteProfileBinding: (platform: string) =>
    productsDeleteProductProfileBinding(platform),
};
