# �️ Hướng Dẫn Thêm Media cho README - Windows Desktop App

Tài liệu này hướng dẫn cách tạo và thêm hình ảnh, GIF cho README của ứng dụng Windows desktop.

## 📁 Cấu Trúc Thư Mục Media

```
docs/
├── images/                     # Hình ảnh tĩnh (PNG, JPG)
│   ├── app_logo.png               # Logo ứng dụng (120x120px)
│   ├── features_overview.png      # Tổng quan tính năng (800x400px)
│   ├── learning_methods.png       # Phương pháp học tập (600x300px)
│   ├── study_modes.png            # Chế độ học tập (700x350px)
│   ├── light_theme.png            # Giao diện sáng (300x500px)
│   ├── dark_theme.png             # Giao diện tối (300x500px)
│   ├── desktop_layout.png         # Layout desktop (300x500px)
│   ├── project_structure.png      # Cấu trúc dự án (600x400px)
│   ├── user_guide_banner.png      # Banner hướng dẫn (700x200px)
│   ├── learning_algorithms.png    # Thuật toán học tập (800x400px)
│   ├── leitner_boxes.png          # Hệ thống hộp Leitner (600x300px)
│   ├── spaced_repetition_curve.png # Đường cong SR (600x300px)
│   ├── windows_home_light.png     # Màn hình chính sáng (600x800px)
│   ├── windows_home_dark.png      # Màn hình chính tối (600x800px)
│   ├── windows_vocab_list.png     # Danh sách từ vựng (500x600px)
│   ├── windows_add_vocab.png      # Thêm từ vựng (500x600px)
│   ├── windows_edit_vocab.png     # Chỉnh sửa từ vựng (500x600px)
│   ├── windows_leitner_boxes.png  # Hộp Leitner (500x600px)
│   ├── windows_spaced_repetition.png # Spaced Repetition (500x600px)
│   ├── windows_quiz_mode.png      # Quiz Mode (500x600px)
│   ├── windows_statistics.png     # Thống kê (500x600px)
│   ├── windows_progress.png       # Tiến độ (500x600px)
│   └── windows_achievements.png   # Thành tích (500x600px)
├── gifs/                       # File GIF demo
│   ├── windows_home_screen_demo.gif        # Demo màn hình chính
│   ├── windows_add_vocabulary_demo.gif     # Demo thêm từ vựng
│   ├── windows_quiz_demo.gif              # Demo quiz
│   ├── windows_leitner_demo.gif           # Demo hệ thống Leitner
│   ├── windows_spaced_repetition_demo.gif # Demo spaced repetition
│   ├── windows_theme_toggle_demo.gif      # Demo chuyển theme
│   ├── add_vocabulary_step_by_step.gif    # Thêm từ từng bước
│   ├── leitner_system_flow.gif            # Luồng hệ thống Leitner
│   ├── spaced_repetition_flow.gif         # Luồng spaced repetition
│   ├── quiz_features.gif                  # Tính năng quiz
│   └── algorithm_visualization.gif        # Minh họa thuật toán
└── MEDIA_GUIDE.md              # File hướng dẫn này
```

## 🎬 Hướng Dẫn Tạo GIF Demo cho Windows Desktop

### 1. Sử dụng Screen Recording
**Công cụ đề xuất cho Windows:**
- **OBS Studio**: Miễn phí, mạnh mẽ, hỗ trợ recording desktop
- **ScreenToGif**: Chuyên dụng cho tạo GIF từ screen recording
- **Windows Game Bar**: Built-in Windows 10/11 (Win + G)
- **Camtasia**: Professional screen recording

### 2. Cài Đặt Recording cho Desktop App
- **Độ phân giải**: 800x600px hoặc 1024x768px (cho desktop demos)
- **Frame rate**: 15-20 FPS
- **Thời lượng**: 5-10 giây
- **File size**: < 5MB mỗi GIF
- **Window focus**: Chỉ record cửa sổ ứng dụng, không record desktop

### 3. Nội Dung GIF Cần Ghi cho Windows App

#### `windows_home_screen_demo.gif`
- Mở app → hiển thị màn hình chính desktop
- Cuộn danh sách từ vựng
- Hiển thị các thống kê và navigation

#### `windows_add_vocabulary_demo.gif`
- Nhấn nút thêm (+) hoặc menu
- Điền form thêm từ vựng trên desktop
- Lưu và quay về danh sách

#### `windows_quiz_demo.gif`
- Vào chế độ quiz từ menu/button
- Trả lời vài câu hỏi với mouse/keyboard
- Hiển thị kết quả trên desktop

#### `windows_leitner_demo.gif`
- Vào hệ thống Leitner
- Xem các hộp từ vựng với layout desktop
- Demo học một từ với interaction

#### `windows_spaced_repetition_demo.gif`
- Vào chế độ spaced repetition
- Ôn tập một từ trên giao diện desktop
- Đánh giá mức độ nhớ

#### `windows_theme_toggle_demo.gif`
- Chuyển từ light theme sang dark theme
- Hiển thị sự thay đổi toàn bộ ứng dụng desktop

## 🖼️ Hướng Dẫn Tạo Hình Ảnh

### 1. Screenshots
- Chụp màn hình trên thiết bị thực
- Crop và resize theo kích thước yêu cầu
- Tối ưu hóa chất lượng và dung lượng

### 2. Mockups và Designs
**Công cụ đề xuất:**
- **Figma**: Tạo mockup và infographic
- **Canva**: Tạo banner và poster
- **Adobe XD**: Thiết kế UI mockup

### 3. Tối Ưu Hóa
- **Format**: PNG cho logo, SVG cho icons
- **Compression**: Sử dụng TinyPNG hoặc ImageOptim
- **Responsive**: Tạo nhiều kích thước khác nhau

## 📋 Checklist Hoàn Thành

### Hình Ảnh Tĩnh
- [ ] `app_logo.png` - Logo ứng dụng
- [ ] `features_overview.png` - Tổng quan tính năng
- [ ] `learning_methods.png` - Phương pháp học tập
- [ ] `study_modes.png` - Chế độ học tập
- [ ] `light_theme.png` - Giao diện sáng
- [ ] `dark_theme.png` - Giao diện tối
- [ ] `responsive_design.png` - Responsive design
- [ ] `project_structure.png` - Cấu trúc dự án
- [ ] `user_guide_banner.png` - Banner hướng dẫn
- [ ] `learning_algorithms.png` - Thuật toán học tập
- [ ] `leitner_boxes.png` - Hệ thống hộp Leitner
- [ ] `spaced_repetition_curve.png` - Đường cong Spaced Repetition

### GIF Demo
- [ ] `home_screen_demo.gif` - Demo màn hình chính
- [ ] `add_vocabulary_demo.gif` - Demo thêm từ vựng
- [ ] `quiz_demo.gif` - Demo quiz
- [ ] `leitner_demo.gif` - Demo hệ thống Leitner
- [ ] `spaced_repetition_demo.gif` - Demo spaced repetition
- [ ] `theme_toggle_demo.gif` - Demo chuyển theme
- [ ] `add_vocabulary_step_by_step.gif` - Thêm từ từng bước
- [ ] `leitner_system_flow.gif` - Luồng hệ thống Leitner
- [ ] `spaced_repetition_flow.gif` - Luồng spaced repetition
- [ ] `quiz_features.gif` - Tính năng quiz
- [ ] `algorithm_visualization.gif` - Minh họa thuật toán

## 🔗 Tips và Best Practices

1. **Consistency**: Giữ style và color scheme nhất quán
2. **Quality**: Đảm bảo hình ảnh sắc nét và rõ ràng
3. **Size**: Tối ưu dung lượng file để tải nhanh
4. **Accessibility**: Thêm alt text mô tả cho screen reader
5. **Responsive**: Test hiển thị trên nhiều kích thước màn hình
6. **Update**: Cập nhật media khi có thay đổi UI/UX

## 📝 Ghi Chú

- Tất cả file media nên được commit vào repository
- Sử dụng relative path để đảm bảo hoạt động trên mọi platform
- Thường xuyên kiểm tra link media trong README
- Backup media files ở nơi an toàn
