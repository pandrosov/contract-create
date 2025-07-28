from app.models.log import Log

def get_logs(db, user_id=None, action=None):
    query = db.query(Log)
    if user_id is not None:
        query = query.filter(Log.user_id == user_id)
    if action is not None:
        query = query.filter(Log.action == action)
    return query.order_by(Log.timestamp.desc()).all() 