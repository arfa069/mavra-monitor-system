import { AnimatePresence, motion, useReducedMotion } from "framer-motion";
import type { ReactNode } from "react";
import type { MotionSpeed } from "@/shared/types/motion";

const SPRING_CONFIG_BY_SPEED = {
  fast: { stiffness: 400, damping: 25 },
  normal: { stiffness: 300, damping: 20 },
  slow: { stiffness: 200, damping: 15 },
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

  const variants = {
    initial: {
      opacity: 0,
      y: prefersReducedMotion ? 0 : 30,
    },
    animate: {
      opacity: 1,
      y: 0,
    },
    exit: {
      opacity: 0,
      y: prefersReducedMotion ? 0 : -30,
    },
  };

  const transition = prefersReducedMotion
    ? { duration: 0.01 }
    : {
        type: "spring" as const,
        stiffness: SPRING_CONFIG_BY_SPEED[speed].stiffness,
        damping: SPRING_CONFIG_BY_SPEED[speed].damping,
        opacity: { duration: OPACITY_DURATION_BY_SPEED[speed], ease: "easeOut" },
      };

  return (
    <AnimatePresence mode="wait">
      <motion.div
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
      </motion.div>
    </AnimatePresence>
  );
}

