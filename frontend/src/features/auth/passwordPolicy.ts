export const strongPasswordMessage =
  "Password must be at least 10 characters and include uppercase, lowercase, number, and special character";

export function validateStrongPassword(value: string): boolean {
  if (value.length < 10) return false;

  const hasUppercase = /[A-Z]/.test(value);
  const hasLowercase = /[a-z]/.test(value);
  const hasDigit = /\d/.test(value);
  const hasSpecial = /[^A-Za-z0-9\s]/.test(value);

  return hasUppercase && hasLowercase && hasDigit && hasSpecial;
}

export function strongPasswordRule() {
  return {
    validator(_: unknown, value: string) {
      if (!value) {
        return Promise.resolve();
      }
      if (!validateStrongPassword(value)) {
        return Promise.reject(new Error(strongPasswordMessage));
      }
      return Promise.resolve();
    },
  };
}
