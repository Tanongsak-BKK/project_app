# Travel App (Project App)

แอปพลิเคชันสำหรับการท่องเที่ยว (Travel App) พัฒนาด้วย **Flutter** โดยแอปนี้เป็นโปรเจคสำหรับการจัดการและแสดงผลข้อมูลสถานที่ท่องเที่ยว พร้อมกับระบบยืนยันตัวตน แผนที่ และฐานข้อมูลออนไลน์

## 📱 ฟีเจอร์หลักๆ ที่คาดว่ามีในแอป
- ระบบลงชื่อเข้าใช้ (Authentication)
- การแสดงผลแผนที่ ค้นหาและดูตำแหน่งสถานที่ท่องเที่ยว (Maps & Location)
- การจัดการข้อมูลสถานที่
- การจัดการและแสดงผลรูปภาพพร้อมวิดีโอ
- UI ที่ออกแบบมาให้เข้ากันได้กับทุกขนาดหน้าจอ 

## 🛠 เครื่องมือและเทคโนโลยีที่ใช้ (Tools & Technologies)

โปรเจคนี้มีการใช้งาน Packages และเครื่องมือต่าง ๆ ที่สำคัญ ดังนี้:

### 1. Framework & Core
- **[Flutter](https://flutter.dev/) (SDK ^3.8.1):** เฟรมเวิร์กหลักในการพัฒนาแอปพลิเคชัน
- **Provider:** สำหรับจัดการ State Management ภายในแอปพลิเคชัน

### 2. Backend & Database (Firebase)
- **Firebase Auth / Google Sign-In / Web Auth 2:** ระบบยืนยันตัวตน (Authentication) เพื่อให้ผู้ใช้ล็อกอิน
- **Cloud Firestore:** ฐานข้อมูล NoSQL แบบเรียลไทม์ สำหรับบันทึกข้อมูลต่างๆ ของแอป
- **Firebase Storage:** บริการเก็บไฟล์รูปภาพ และวิดีโอ (Cloud Storage)

### 3. Maps & Location Services (แผนที่และการระบุตำแหน่ง)
- **Google Maps Flutter:** สำหรับการแสดงแผนที่ (Google Maps) ภายในแอป
- **Location & Geolocator:** ใช้เข้าถึงพิกัดและตำแหน่งปัจจุบันของผู้ใช้งาน (GPS)
- **Geocoding & Google Places SDK:** แปลงพิกัดเป็นชื่อสถานที่จริง และค้นหาสถานที่

### 4. UI & Design (การออกแบบหน้าจอผู้ใช้)
- **Google Fonts:** จัดการรูปแบบฟอนต์ให้สวยงาม
- **Curved Navigation Bar:** แถบเมนูด้านล่าง (Bottom Navigation) แบบโค้ง
- **Introduction Screen & Smooth Page Indicator:** หน้าจอแนะนำการใช้งานแอปเมื่อเปิดแอปครั้งแรก (Onboarding)
- **Device Preview Plus:** ตัวช่วยในการพรีวิวหน้าจอและทดสอบ UI บนหน้าจอหลายขนาด
- **Cupertino Icons & Flutter SVG:** สำหรับใช้งาน Icons และไฟล์กราฟิกแบบ Vector

### 5. Media & Local Storage (สื่อและการจัดเก็บข้อมูลในเครื่อง)
- **Image Picker & Video Player:** ถ่ายรูป เลือกรูปภาพจากอัลบั้มเครื่อง และเครื่องมือสำหรับเล่นวิดีโอ
- **Flutter Image Compress:** บีบอัดรูปภาพก่อนนำไปใช้งานหรืออัปโหลด เพื่อให้ประหยัดพื้นที่จัดเก็บ
- **Cached Network Image:** เครื่องมือโหลดรูปภาพจากอินเทอร์เน็ตและเก็บแคช (Cache) ไว้ในเครื่องเพื่อการโหลดที่รวดเร็วขึ้นในครั้งถัดไป
- **Shared Preferences:** เก็บข้อมูลขนาดเล็กหรือการตั้งค่าต่างๆ ไว้ในเครื่อง (Local Storage)

## 🚀 การเปิดใช้งาน (Getting Started)

1. ทำการ Clone โปรเจคหรือเปิดโฟลเดอร์โปรเจคนี้บน IDE ของคุณ (เช่น VS Code หรือ Android Studio)
2. รันคำสั่งเพื่อดาวน์โหลดและติดตั้ง Packages ทั้งหมด:
   ```bash
   flutter pub get
   ```
3. เลือกรันแอปพลิเคชัน (สามารถรันผ่าน Emulator หรืออุปกรณ์จริงได้):
   ```bash
   flutter run
   ```

*(หมายเหตุ: การใช้งานแผนที่ และเทคโนโลยีฝั่ง Backend อย่าง Firebase ต้องมีการตั้งค่าไฟล์ Configuration เช่น `google-services.json` สำหรับ Android และ `GoogleService-Info.plist` สำหรับ iOS หรือ API Key จาก Google Cloud Console จึงจะทำงานได้อย่างสมบูรณ์)*
