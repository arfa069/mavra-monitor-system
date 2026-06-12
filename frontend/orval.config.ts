import { defineConfig } from 'orval';

export default defineConfig({
  api: {
    input: './openapi.json',
    output: {
      mode: 'tags-split',
      target: 'src/shared/api/generated/endpoints.ts',
      schemas: 'src/shared/api/generated/models',
      client: 'react-query',
      override: {
        mutator: {
          path: 'src/shared/api/mutator.ts',
          name: 'customInstance',
        },
      },
    },
    hooks: {
      afterAllFilesWrite: 'eslint --fix',
    },
  },
});
