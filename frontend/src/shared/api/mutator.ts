import type { AxiosRequestConfig, AxiosError } from 'axios';
import api from './client';

export const customInstance = <T>(
  config: AxiosRequestConfig,
  options?: AxiosRequestConfig,
): Promise<T> => {
  const promise = api({
    ...config,
    ...options,
  }).then(({ data }) => data);

  return promise;
};

// Error type for Orval generated hooks
export type ErrorType<Error> = AxiosError<Error>;
export type BodyType<BodyData> = BodyData;
