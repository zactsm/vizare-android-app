# VIZARE - AR Real Estate Application

VIZARE is a cutting-edge real estate platform built with Flutter that integrates Augmented Reality (AR) to provide an immersive property viewing experience. The application supports multiple user roles (Homebuyer, Homeowner, Admin) and features a robust backend architecture.

## 🚀 Features

-   **AR Property Viewing**: View 3D models (.glb) of properties directly in the app.
-   **Multi-Role System**:
    -   **Homebuyers**: Search listings, save favorites, and send inquiries.
    -   **Homeowners**: Post new properties, manage listings (edit/delete), and respond to inquiries.
    -   **Admins**: Review and approve/reject pending property listings.
-   **Media Management**: Integrated with Cloudinary for efficient image and 3D model hosting.
-   **Interactive Maps**: Search for properties and set preferred locations using Google Maps.
-   **Inquiry System**: Real-time messaging and email alerts via Firebase and EmailJS.
-   **Secure Authentication**: Supports Email/Password login and Google Sign-In.

## 🛠️ Tech Stack

-   **Frontend**: Flutter (Dart)
-   **Backend**: PHP (Deployed on Google App Engine)
-   **Database**: 
    -   Aiven MySQL (User and Property data)
    -   Firebase Firestore (Real-time inquiries and support tickets)
-   **Storage**: Firebase Storage & Cloudinary
-   **APIs**: Google Maps API, Google Sign-In, EmailJS

## 📦 Prerequisites

-   Flutter SDK: `^3.8.1`
-   Android Studio / VS Code
-   A Firebase Project
-   Cloudinary Account
-   Google Maps API Key

## ⚙️ Setup & Installation

1.  **Clone the Repository**:
    ```bash
    git clone <repository-url>
    cd vizare-app
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Environment Configuration**:
    Create a `.env` file in the root directory and add your credentials:
    ```env
    EMAILJS_SERVICE_ID=your_service_id
    EMAILJS_TEMPLATE_ID=your_template_id
    EMAILJS_PUBLIC_KEY=your_public_key

    GOOGLE_MAPS_API_KEY=your_google_maps_key

    CLOUDINARY_CLOUD_NAME=your_cloud_name
    CLOUDINARY_UPLOAD_PRESET=your_upload_preset

    BACKEND_URL=https://your-app-engine-url.appspot.com
    ```

4.  **Firebase Setup**:
    -   Place your `google-services.json` in `android/app/`.
    -   Place your `GoogleService-Info.plist` in `ios/Runner/`.

5.  **Run the App**:
    ```bash
    flutter run
    ```

## 📂 Project Structure

-   `lib/models/`: Data models (e.g., `Property`).
-   `lib/pages/`: UI screens for Homebuyer, Homeowner, and Admin.
-   `lib/pages/utils/`: Shared utilities like `ApiService` and page transitions.
-   `assets/`: Fonts, icons, and static images.

## 🛡️ Security

Sensitive keys and backend URLs are managed via `flutter_dotenv` to ensure they are not hardcoded in the source code. Always use the `ApiService` for backend communication to maintain consistent error handling and security standards.

---
Developed by Muazz for the VIZARE Real Estate Platform.
