# Lumina - Smart Inventory Management

**Lumina** is a modern, premium inventory management and Point of Sale (POS) application built with Flutter. It streamlines product tracking, sales recording, and business analytics with a beautiful, user-centric interface.

## 🚀 Features

### 🛒 Product Management
*   **Comprehensive Listing:** View products in a responsive grid layout with rich details (Image, Name, Category, Stock, Prices).
*   **Smart Search:** Filter products instantly by name or **scan barcodes** for quick access.
*   **Category Filtering:** Dynamic category chips for easy organization.

### 🛡️ Admin Dashboard
*   **Inventory Control:**
    *   **Add/Edit Products:** Full product lifecycle management including image uploading (via Cloudinary) and barcode assignment.
    *   **Stock Tracking:** Real-time visibility of stock levels with visual indicators (In Stock/Out of Stock).
    *   **Quick Sales:** "Sell Item" feature directly from the product card with automatic transaction logging and stock decrement.
*   **Analytics:** Visual insights into business performance:
    *   Total Revenue & Profit Cards.
    *   Profit Trend Line Chart (Last 7 Days).
    *   Category Performance Pie Chart.
    *   Top Selling Products list.
*   **User Management:** Overview of registered users (Admin view).

### 🔐 Authentication & Security
*   **Secure Login/Signup:** Email and password authentication via Firebase Auth.
*   **Role-Based Access:** Distinct features for Admins vs. Standard Users.

### 🎨 UI/UX Design
*   **Modern Aesthetic:** Clean, "Lumina" branded interface using deep indigo and vibrant accents.
*   **Responsive:** optimized for varied screen sizes.
*   **Fluid Animations:** Smooth transitions and interactive elements.

## 🛠️ Tech Stack & Dependencies

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **Backend:** [Firebase](https://firebase.google.com/) (Auth, Firestore)
*   **Image Storage:** [Cloudinary](https://cloudinary.com/)
*   **State Management:** `provider`
*   **Key Packages:**
    *   `mobile_scanner`: For barcode scanning integration.
    *   `fl_chart`: For beautiful analytics charts.
    *   `cloudinary_flutter`: For handling image assets.
    *   `google_fonts`: For premium typography (Poppins).
    *   `flutter_animate`: For UI animations.

## ⚙️ Installation & Setup

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/shoibahmad/lumina-stock.git
    cd lumina-stock
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup**
    *   Create a project in the [Firebase Console](https://console.firebase.google.com/).
    *   Add Android/iOS apps to your Firebase project.
    *   Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in `android/app/` and `ios/Runner/` respectively.

4.  **Cloudinary Setup**
    *   Sign up for [Cloudinary](https://cloudinary.com/).
    *   Configure your Cloud Name and Upload Preset in `lib/core/services/cloudinary_service.dart` (or environment variables).

5.  **Run the App**
    ```bash
    flutter run
    ```

## 📂 Project Structure

```
lib/
├── core/             # Core utilities (Theme, Services, Constants)
├── features/         # Feature-based folder structure
│   ├── admin/        # Admin-specific pages (Add Product, Analytics, Scanner)
│   ├── auth/         # Login & Signup pages
│   ├── home/         # Product Listing & Main Dashboard
│   ├── profile/      # User Profile
│   └── splash/       # Splash Screen
├── models/           # Data models (Product, SaleTransaction)
└── main.dart         # Entry point
```

## 🔮 Future Roadmap

*   [ ] **Detailed POS:** Multi-item cart for processing bulk sales.
*   [ ] **Export Reports:** PDF/Excel export for sales and inventory data.
*   [ ] **Notifications:** Low stock alerts.
*   [ ] **Dark Mode:** Full system-wide dark theme support.

## 📝 License

This project is open-source and available under the [MIT License](LICENSE).
