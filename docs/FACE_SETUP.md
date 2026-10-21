# Face recognition setup

The backend uses trained **YuNet 2023mar face detection** and **SFace 2021dec identity embeddings**, running on CPU through OpenCvSharp 4.13.0.20260627 and the matching Windows native runtime. It detects exactly one face, aligns all five landmarks to SFace's 112x112 canonical coordinates, converts BGR to RGB with scale 1 and zero mean, runs SFace, L2 normalizes its 128 features, and compares cosine similarity. Gradient/checkerboard image statistics are no longer accepted as face features.

## Install on Windows x64

Use .NET 10 and the Microsoft Visual C++ 2015-2022 x64 redistributable required by the [OpenCvSharp Windows runtime](https://github.com/shimat/opencvsharp). From the repository root:

```powershell
./scripts/Initialize-FaceModels.ps1 -IncludeTestImages
dotnet restore tests/phamlehuyhoang.Tests/phamlehuyhoang.Tests.csproj
dotnet test tests/phamlehuyhoang.Tests/phamlehuyhoang.Tests.csproj --filter FullyQualifiedName~FaceMatchingTests
```

The script downloads official model weights to the gitignored `.local/models/face` directory and verifies SHA256 before replacing a file. It is safe to rerun. Test images are optional for running the server, required for the inference tests. Models are deliberately not included as large Git binaries. A missing file, incorrect hash, or unavailable native runtime fails recognition with a setup instruction; there is no fallback matcher.

The service searches ancestors of the working directory and application directory for `.local/models/face`. For deployment, copy the weights and their licenses into your deployment's model directory and set `Face__ModelDirectory` to its absolute path. This repository currently includes the Windows runtime; Linux deployments need a matching OpenCvSharp Linux native runtime and their own verification.

## Pinned models and licenses

Source revision: [opencv_zoo 48b10fa505aeb51fbd127fc60a5c660040e823b7](https://github.com/opencv/opencv_zoo/tree/48b10fa505aeb51fbd127fc60a5c660040e823b7).

| File | SHA256 | License |
|---|---|---|
| face_detection_yunet_2023mar.onnx | `8f2383e4dd3cfbb4553ea8718107fc0423210dc964f9f4280604804ed2552fa4` | [MIT, copyright Shiqi Yu](https://github.com/opencv/opencv_zoo/blob/48b10fa505aeb51fbd127fc60a5c660040e823b7/models/face_detection_yunet/LICENSE) |
| face_recognition_sface_2021dec.onnx | `0ba9fbfa01b5270c96627c4ef784da859931e02f04419c829e83484087c34e79` | [Apache 2.0](https://github.com/opencv/opencv_zoo/blob/48b10fa505aeb51fbd127fc60a5c660040e823b7/models/face_recognition_sface/LICENSE) |

The setup script keeps both license texts beside the weights. OpenCvSharp is Apache 2.0. The released managed package does not expose `FaceRecognizerSF`; the service uses its DNN `Net` API with [OpenCV's exact SFace preprocessing and canonical landmarks](https://github.com/opencv/opencv/blob/4.13.0/modules/objdetect/src/face_recognize.cpp), and a least-squares five-point similarity alignment.

## Threshold and old enrollments

Default cosine threshold: **0.363**, the LFW operating point in the [official OpenCV SFace tutorial](https://docs.opencv.org/4.13.0/d0/dd4/tutorial_dnn_face.html). Cosine is a similarity score, not an identity probability or confidence percentage. This benchmark threshold is a starting point; it does not establish false-accept performance for this application's users and cameras.

Each stored embedding is now 524 bytes: UTF-8 header `SFACE2021:v1` (12 bytes) followed by 128 little-endian float32 values (512 bytes). The header identifies the model/format. The former unversioned 512-byte brightness vectors are explicitly rejected, even though SFace also outputs 128 floats. Existing users must log in with their password and register their face again. No database schema migration is necessary for the existing byte-array column.

Images with no detected face or multiple faces are rejected. Input images are limited to 5 MB and 16 million decoded pixels; face bounding boxes must be at least 64 pixels in the resized detection image. Detection keeps aspect ratio and caps the longest side at 1280 pixels.

## Inference fixtures and scope

The optional test fixtures are downloaded, hash-pinned, and retained only in `.local`:

- `astronaut.png`: Eileen Collins NASA portrait from [scikit-image v0.24.0](https://github.com/scikit-image/scikit-image/blob/v0.24.0/skimage/data/astronaut.png), SHA256 `88431cd9653ccd539741b555fb0a46b61558b301d4110412b5bc28b5e3ea6cb5`. [scikit-image documents it as public domain](https://scikit-image.org/docs/stable/api/skimage.data.html#skimage.data.astronaut).
- `collins-shuttle.jpg`: a separate July 1999 photograph of the same astronaut from [NASA's image article](https://www.nasa.gov/image-article/astronaut-eileen-collins-nasas-first-female-shuttle-commander/), credited NASA, SHA256 `294434d55c19f00bfe4c078da58a93c908bc3df20e6925daff7c71830986e667`. See [NASA image usage guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media/).
- `grace_hopper.jpg`: Grace Hopper's US Navy portrait as distributed in [Matplotlib v3.10.0 sample data](https://github.com/matplotlib/matplotlib/blob/v3.10.0/lib/matplotlib/mpl-data/sample_data/grace_hopper.jpg), SHA256 `a8ca6d734765703b09728ab47fe59f473d93ae3967fc24c7c0288c3c7adb7130`. This US government photograph is public domain; it is a different identity from Collins.

Tests exercise actual native detector and recognition inference, two separate photographs of one person, a different person, no-face patterns, and a composite containing two faces. These are regression checks, not a representative biometric evaluation.

**Liveness is not implemented.** A photograph or screen replay may still match. The camera capture UI and this identity matcher do not establish that a live person is present. Test physical camera enrollment/login separately when a device is available. SMTP configuration is independent of face model setup.
