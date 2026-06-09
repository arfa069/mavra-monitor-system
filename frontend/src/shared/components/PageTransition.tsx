import { AnimatePresence, m, useReducedMotion } from "framer-motion";
import { useMemo, type ReactNode } from "react";
import type { MotionSpeed } from "@/shared/types/motion";

const SPRING_CONFIG_BY_SPEED = {
  fast: { stiffness: 220, damping: 24 },
  normal: { stiffness: 140, damping: 18 },
  slow: { stiffness: 70, damping: 13 },
};

const OPACITY_DURATION_BY_SPEED = {
  fast: 0.15,
  normal: 0.25,
  slow: 0.4,
};

interface PageTransitionProps {
  children: ReactNode;
  pathname: string;
  speed: MotionSpeed;
}

export default function PageTransition({
  children,
  pathname,
  speed,
}: PageTransitionProps) {
  const prefersReducedMotion = useReducedMotion();

  const variants = useMemo(
    () => ({
      initial: {
        opacity: 0,
        y: prefersReducedMotion ? 0 : 12,
      },
      animate: {
        opacity: 1,
        y: 0,
      },
      exit: {
        opacity: 0,
        y: prefersReducedMotion ? 0 : -12,
      },
    }),
    [prefersReducedMotion],
  );

  const transition = useMemo(
    () =>
      prefersReducedMotion
        ? { duration: 0.01 }
        : {
            type: "spring" as const,
            stiffness: SPRING_CONFIG_BY_SPEED[speed].stiffness,
            damping: SPRING_CONFIG_BY_SPEED[speed].damping,
            opacity: {
              duration: OPACITY_DURATION_BY_SPEED[speed],
              ease: "easeOut",
            },
          },
    [prefersReducedMotion, speed],
  );

  return (
    <AnimatePresence mode="wait">
      <m.div
        key={pathname}
        data-page-transition={pathname}
        data-motion-speed={speed}
        variants={variants}
        initial="initial"
        animate="animate"
        exit="exit"
        transition={transition}
        style={{
          position: "relative",
          zIndex: 1,
          width: "100%",
          minHeight: "calc(100vh - 152px)",
          willChange: "opacity, transform",
        }}
      >
        {children}
      </m.div>
    </AnimatePresence>
  );
}
