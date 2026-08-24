import os

from .tokens import token


def reduced_motion_enabled() -> bool:
    value = os.environ.get("NYXNIRI_REDUCED_MOTION", "").strip().lower()
    return value in {"1", "true", "yes", "on"}


class Spring:
    def __init__(self, initial: float = 0.0, omega: float | None = None, zeta: float | None = None):
        self.current = initial
        self.target = initial
        self.velocity = 0.0
        self.omega = float(omega if omega is not None else token("motion", "spring_omega", 14.0))
        self.zeta = float(zeta if zeta is not None else token("motion", "spring_damping", 0.70))

    def update(self, dt: float) -> bool:
        if reduced_motion_enabled():
            self.current = self.target
            self.velocity = 0.0
            return False
        dt = min(0.05, max(0.001, dt))
        force = -(self.omega**2) * (self.current - self.target) - 2.0 * self.zeta * self.omega * self.velocity
        self.velocity += force * dt
        self.current += self.velocity * dt
        if abs(self.current - self.target) > 0.001 or abs(self.velocity) > 0.001:
            return True
        self.current = self.target
        self.velocity = 0.0
        return False
