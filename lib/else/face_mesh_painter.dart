import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum DetectionMode { boundingBox, faceMesh }

class FaceMeshPainter extends CustomPainter {
  final List<Face> faces;
  final DetectionMode mode;

  FaceMeshPainter(this.faces, this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint landmarkPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    for (Face face in faces) {
      if (mode == DetectionMode.boundingBox) {
        Rect rect = face.boundingBox;
        canvas.drawRect(rect, boxPaint);
      }

      if (mode == DetectionMode.faceMesh) {
        for (FaceLandmarkType type in FaceLandmarkType.values) {
          final FaceLandmark? landmark = face.landmarks[type];

          if (landmark != null) {
            double x = landmark.position.x.toDouble();
            double y = landmark.position.y.toDouble();

            if (x > 0 && y > 0 && x < size.width && y < size.height) {
              canvas.drawCircle(Offset(x, y), 3.0, landmarkPaint);
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(FaceMeshPainter oldDelegate) {
    return true;
  }
}
