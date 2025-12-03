# faculty_admin/services/__init__.py

# Import services safely to avoid runtime errors on Render

try:
    from .case_service import CaseService
except Exception:
    CaseService = None

try:
    from .broadcast_service import BroadcastService
except Exception:
    BroadcastService = None

try:
    from .attendance_service import AttendanceService
except Exception:
    AttendanceService = None

try:
    from .predictive_service import PredictiveService
except Exception:
    PredictiveService = None


__all__ = [
    'CaseService',
    'BroadcastService',
    'AttendanceService',
    'PredictiveService',
]