---
trigger: always_on
---

I'm building a post a Pose Signature System to record perfect athlete movements and to compare them to players doing the same movement

Below are some technical suggestion from aI on how to build it
Save to the database the result of the of the pose estimations for the professional athlete (aka as admin system recording of the gold standar) and the players trying to improve their forms.The information being save as a reference could be a list of frames, each containing a map of joint coordinates, and if possible angles. The information being saved from players could be an analysis  with a score for each movement (0% to 100%), the repetitions, the normalized score for the set of repetitions. We can use that to track the progress in a chart later

Part 1: The Admin System (Recording the "Gold Standard")
Instead of just saving one frame, you need to record a "Reference Repetition."
Normalization: To make your video work for any user, you must normalize the coordinates before saving them to the database.
Translation: Set the MidHip (average of left/right hip) to $(0,0,0)$.
Scaling: Measure the distance between the LeftShoulder and RightShoulder. Divide all $(x, y, z)$ coordinates by this distance. This ensures that whether you are 2 meters or 5 meters from the camera, the "size" of the pose is the same.
Data Structure (NoSQL):
Save your exercise document like this:
JSON
{
  "exercise_name": "Squat",
  "thresholds": { "knee_angle_min": 70, "back_angle_max": 165 },
  "reference_sequence": [
    {"frame": 0, "landmarks": {"left_knee_angle": 175, "hip_y": 0.1}},
    {"frame": 5, "landmarks": {"left_knee_angle": 140, "hip_y": 0.3}},
    ... // Keyframes of one perfect rep
  ]
}


Recording: Record yourself doing one perfect repetition slowly. The app should extract the landmarks and save the sequence of angles to your database.

Part 2: The Athlete System (Real-Time Feedback)
This is where the State Machine and DTW come together.
1. The State Machine (The Rep Counter)
You don't need DTW to count reps; a state machine is more robust.
State 0: Resting (Athlete is standing straight).
State 1: Descending (Knee angle is decreasing).
State 2: Peak (Knee angle hits the target depth, e.g., $<90^\circ$).
State 3: Ascending (Knee angle is increasing).
Back to State 0: Rep count increments.
2. Dynamic Time Warping (The Form Scorer)
While the athlete is in State 1 or 3, you compare their "path" to your "Gold Standard" from the database.
If the athlete moves their knees inward (valgus), the DTW distance for the "Knee-to-Knee" distance will spike compared to your perfect recording.
3. Feedback Logic (Audio & Visual)
You need a "Buffer" to prevent the app from screaming at the user for a single glitchy frame.
Feedback Type
Trigger
Implementation
Visual (Good)
State Machine is progressing & DTW distance is low.
Draw the skeleton in Green.
Visual (Warning)
DTW distance exceeds "Warning" threshold for >5 frames.
Draw the skeleton in Yellow/Orange.
Audio (Correction)
Angle exceeds "Critical" threshold (e.g., back is dangerously bent).
Trigger flutter_tts: "Keep your back straight."
Auto-Stop
No state change detected for 5 seconds.
Timer.cancel() and show the summary screen.


4. How to Implement in Flutter (Step-by-Step)
Step A: The Vector Math
Create a helper function to turn ML Kit landmarks into angles.
Dart
double calculateAngle(PoseLandmark first, PoseLandmark mid, PoseLandmark last) {
  // Standard vector math: acos((ba·bc) / (|ba|*|bc|))
  // Use the x, y, and z coordinates provided by ML Kit
}

Step B: The Comparison Loop
In your camera.startImageStream, you will:
Get the Pose from ML Kit.
Normalize the landmarks.
Check the State Machine (Are they at the bottom of the squat yet?).
If they are "in motion," compare the current angles to the reference_sequence using a simplified DTW (or just a simple Euclidean distance for performance).
Audio Feedback: If backAngle < 160, and the last time you spoke was $>3$ seconds ago, trigger the voice.
Step C: The "Correct Form" Video
You only need one video of yourself for the "Gold Standard," but it must be from the side profile for exercises like squats or deadlifts (to see back curvature) or front profile for jumping jacks.

Final Plan Suggestion:
Week 1: Build the "Admin" recorder. Save your normalized joint angles for a "Squat" to a local JSON/NoSQL file.
Week 2: Create the State Machine logic to detect "Down" and "Up" and increment a counter on the screen.
Week 3: Add the "Threshold" logic. If the user's knee doesn't go low enough, don't count the rep and play a "Go lower" sound.

