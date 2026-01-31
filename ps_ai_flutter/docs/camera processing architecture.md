# System Architecture

This document describes the interaction between the core components of the PS AI Flutter application, focusing on the sports capture and tracking functionality.

## Sequence Diagram: Frame Processing

```mermaid
sequenceDiagram
    participant W as SportsCaptureWidget
    participant C as CaptureController (Riverpod)
    participant S as CameraService
    participant M as MLService
    participant U as MLKitUtils
    participant P as TrackingOverlayPainter

    W->>C: initialize()
    C->>S: initialize()
    C->>M: initialize()
    S-->>C: CameraController
    C-->>W: Update State (status: streaming)
    
    loop Every Camera Frame
        S->>C: _processFrame(image)
        C->>U: getRotation() & inputImageFromCameraImage()
        U-->>C: InputImage
        C->>M: processPose(inputImage)
        M-->>C: List<Pose>
        Note over C,M: processObjects every 3rd frame
        C->>M: processObjects(inputImage)
        M-->>C: List<DetectedObject>
        C-->>W: state.copyWith(poses, objects, rotation)
        W->>P: paint(poses, objects, rotation)
        P-->>W: CustomPaint UI
    end
```

## Component Interaction Diagram

```mermaid
graph TD
    subgraph UI Layer
        A[SportsCaptureWidget] --> B[TrackingOverlayPainter]
    end

    subgraph State Management
        C[CaptureController / captureControllerProvider]
    end

    subgraph Services Layer
        D[CameraService]
        E[MLService]
        F[TrackingRepository]
        G[FirestoreService]
        H[MLKitUtils]
    end

    subgraph External
        I[Google ML Kit]
        J[Camera Native API]
        K[Local Storage / JSON]
        L[Firebase Firestore]
    end

    A -- listens to --> C
    C -- manages --> D
    C -- uses --> E
    C -- uses --> F
    C -- uses --> H
    
    D -- interacts with --> J
    E -- interacts with --> I
    F -- interacts with --> K
    G -- interacts with --> L
    
    F -. sync future .-> G
    
    classDef ui fill:#e1f5fe,stroke:#01579b
    classDef state fill:#f3e5f5,stroke:#4a148c
    classDef service fill:#e8f5e9,stroke:#1b5e20
    classDef external fill:#fff3e0,stroke:#e65100
    
    class A,B ui
    class C state
    class D,E,F,G,H service
    class I,J,K,L external
```

## Key Responsibilities

| Component | Responsibility |
|-----------|----------------|
| **SportsCaptureWidget** | Renders the camera preview and overlays. Handles user input (Start/Stop). |
| **CaptureController** | Orchestrates services. Manages processing lifecycle and state. Throttles ML processing. |
| **CameraService** | Wraps the `camera` package. Manages hardware lifecycle and image streaming. |
| **MLService** | Wraps `google_mlkit_pose_detection` and `google_mlkit_object_detection`. |
| **TrackingRepository** | Persists `TrackingSession` data to local files as JSON. |
| **TrackingOverlayPainter** | Translates ML coordinates to UI coordinates and draws shapes. |
| **MLKitUtils** | Handles conversion from `CameraImage` to `InputImage` and orientation math. |
