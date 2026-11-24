from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.db import connection
from django.db.utils import DatabaseError


@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    try:
        connection.ensure_connection()
    except DatabaseError:
        return Response({
            "status": "unavailable",
            "database": "disconnected",
            "version": "1.0.0",
            "project": "Inuka Digital Leap API"
        }, status=503)

    return Response({
        "status": "ok",
        "database": "connected",
        "version": "1.0.0",
        "project": "Inuka Digital Leap API"
    })
