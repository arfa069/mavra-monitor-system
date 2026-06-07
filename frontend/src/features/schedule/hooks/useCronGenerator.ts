import { useCallback, useState } from "react";

export type GeneratorTarget =
  | { type: "platform"; platform: string }
  | { type: "config"; configId: number }
  | { type: "add" };

export function useCronGenerator() {
  const [open, setOpen] = useState(false);
  const [target, setTarget] = useState<GeneratorTarget | null>(null);

  const openGenerator = useCallback((t: GeneratorTarget) => {
    setTarget(t);
    setOpen(true);
  }, []);

  const closeGenerator = useCallback(() => {
    setOpen(false);
    setTarget(null);
  }, []);

  return { open, target, openGenerator, closeGenerator };
}
