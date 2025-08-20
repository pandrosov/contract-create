from app.models.action_log import ActionLog

def get_logs(db, user_id=None, action=None):
    query = db.query(ActionLog)
    if user_id is not None:
        query = query.filter(ActionLog.user_id == user_id)
    if action is not None:
        query = query.filter(ActionLog.action == action)
    return query.order_by(ActionLog.timestamp.desc()).all() 