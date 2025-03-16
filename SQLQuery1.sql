-- Tạo cơ sở dữ liệu QuanLySach
CREATE DATABASE QuanLySach_Final_Spring2025;
GO

-- Sử dụng cơ sở dữ liệu QuanLySach
USE QuanLySach_Final_Spring2025;
GO

-- Tạo bảng Thể loại
CREATE TABLE TheLoai (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaTheLoai NVARCHAR(50) UNIQUE NOT NULL,
    TenTheLoai NVARCHAR(255) NOT NULL,
    TrangThai BIT DEFAULT 1 CHECK (TrangThai IN (0,1))
);
GO

-- Tạo bảng Ngôn Ngữ
CREATE TABLE NgonNgu (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaNgonNgu NVARCHAR(50) UNIQUE NOT NULL,
    TenNgonNgu NVARCHAR(255) NOT NULL,
    TrangThai BIT DEFAULT 1 CHECK (TrangThai IN (0,1))
);
GO

-- Tạo bảng Nhà Xuất Bản
CREATE TABLE NXB (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaNXB NVARCHAR(50) UNIQUE NOT NULL,
    TenNXB NVARCHAR(255) NOT NULL,
    DiaChi NVARCHAR(255),
    SDT VARCHAR(20) CHECK (SDT LIKE '[0-9]%')
);
GO

-- Tạo bảng Tác giả
CREATE TABLE TacGia (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaTacGia NVARCHAR(50) UNIQUE NOT NULL,
    TenTacGia NVARCHAR(255) NOT NULL

);
GO

-- Tạo bảng Sản Phẩm (Sách)
CREATE TABLE SanPham (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaSanPham NVARCHAR(50) UNIQUE NOT NULL,
    TenSanPham NVARCHAR(255) NOT NULL,
    GiaBan DECIMAL(18,2) NOT NULL CHECK (GiaBan >= 0),
    HinhAnh NVARCHAR(255),
    SoLuong INT NOT NULL CHECK (SoLuong >= 0),
    IDTheLoai INT FOREIGN KEY REFERENCES TheLoai(ID),
    IDNgonNgu INT FOREIGN KEY REFERENCES NgonNgu(ID),
    IDNXB INT FOREIGN KEY REFERENCES NXB(ID),
    IDTacGia INT FOREIGN KEY REFERENCES TacGia(ID),
    TrangThai BIT DEFAULT 1 CHECK (TrangThai IN (0,1))
);
GO


-- Tạo bảng Chức vụ
CREATE TABLE ChucVu (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaChucVu NVARCHAR(50) UNIQUE NOT NULL,
    TenChucVu NVARCHAR(255) NOT NULL
);
GO

-- Tạo bảng Nhân Viên
CREATE TABLE NhanVien (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaNhanVien NVARCHAR(50) UNIQUE NOT NULL,
    TenNhanVien NVARCHAR(255) NOT NULL,
    MatKhau VARCHAR(255) NOT NULL,
    SDT VARCHAR(20) CHECK (SDT LIKE '[0-9]%'),
    GioiTinh BIT CHECK (GioiTinh IN (0,1)),
    NgaySinh DATE,
    IDChucVu INT FOREIGN KEY REFERENCES ChucVu(ID),
    TrangThai BIT DEFAULT 1 CHECK (TrangThai IN (0,1))
);
GO

-- Tạo bảng Khách Hàng
CREATE TABLE KhachHang (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaKhachHang VARCHAR(20),
    TenKhachHang NVARCHAR(255) NOT NULL,
    SDT VARCHAR(20) CHECK (SDT LIKE '[0-9]%'),
    Email NVARCHAR(255),
    GioiTinh BIT CHECK (GioiTinh IN (0,1)),
    NgaySinh DATE
);
GO

-- Tạo bảng Phiếu Giảm Giá
CREATE TABLE PhieuGiamGia (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaPhieuGiamGia NVARCHAR(50) UNIQUE NOT NULL,
    TenPhieuGiamGia NVARCHAR(255) NOT NULL,
    SoLuong INT NOT NULL CHECK (SoLuong >= 0),
    NgayBatDau DATE,
    NgayKetThuc DATE,
    SoTienGiam DECIMAL(18,2) NOT NULL CHECK (SoTienGiam >= 0),
	TrangThai BIT DEFAULT 1 CHECK (TrangThai IN (0,1)),
    CONSTRAINT CHK_NgayBatDau_NgayKetThuc CHECK (NgayBatDau <= NgayKetThuc)
);
GO

-- Tạo bảng Hóa Đơn
CREATE TABLE HoaDon (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaHoaDon VARCHAR(20),
    IDNhanVien INT FOREIGN KEY REFERENCES NhanVien(ID),
    IDKhachHang INT FOREIGN KEY REFERENCES KhachHang(ID),
    IDPhieuGiamGia INT FOREIGN KEY REFERENCES PhieuGiamGia(ID),
    TrangThai BIT NOT NULL,
    NgayTao DATE,
    TongTien DECIMAL(18,2) CHECK (TongTien >= 0),
    SoTienGiam DECIMAL(18,2) DEFAULT 0,
    ThanhTien DECIMAL(18,2) DEFAULT 0
);
GO

-- Tạo bảng Chi Tiết Hóa Đơn
CREATE TABLE ChiTietHoaDon (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaChiTietHoaDon VARCHAR(20),
    IDHoaDon INT FOREIGN KEY REFERENCES HoaDon(ID),
    IDSanPham INT FOREIGN KEY REFERENCES SanPham(ID),
    SoLuong INT NOT NULL CHECK (SoLuong > 0)
);
GO

CREATE TRIGGER trg_AutoGenerateMaKhachHang
ON KhachHang
AFTER INSERT
AS
BEGIN
    DECLARE @NewID INT, @NewMaKhachHang VARCHAR(20);
    DECLARE cur CURSOR FOR
    SELECT ID FROM INSERTED;

    OPEN cur;
    FETCH NEXT FROM cur INTO @NewID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Sinh mã dạng "KH" + ID với 3 chữ số (ví dụ: KH001, KH002,...)
        SET @NewMaKhachHang = 'KH' + RIGHT('000' + CAST(@NewID AS VARCHAR(3)), 3);

        -- Cập nhật lại MaKhachHang
        UPDATE KhachHang
        SET MaKhachHang = @NewMaKhachHang
        WHERE ID = @NewID;

        FETCH NEXT FROM cur INTO @NewID;
    END;

    CLOSE cur;
    DEALLOCATE cur;
END;
GO

CREATE TRIGGER trg_AutoGenerateMaHoaDon
ON HoaDon
AFTER INSERT
AS
BEGIN
    -- Biến để lưu ID và mã hóa đơn
    DECLARE @NewID INT, @NewMaHoaDon VARCHAR(20);

    -- Duyệt qua tất cả các bản ghi trong INSERTED
    DECLARE cur CURSOR FOR
    SELECT ID FROM INSERTED;

    OPEN cur;
    FETCH NEXT FROM cur INTO @NewID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Tạo mã hóa đơn theo định dạng "HD" + ID (với 6 chữ số)
        SET @NewMaHoaDon = 'HD' + RIGHT('000' + CAST(@NewID AS VARCHAR(20)), 20);

        -- Cập nhật lại MaHoaDon trong bảng HoaDon
        UPDATE HoaDon
        SET MaHoaDon = @NewMaHoaDon
        WHERE ID = @NewID;

        FETCH NEXT FROM cur INTO @NewID;
    END;

    -- Đóng và giải phóng tài nguyên cursor
    CLOSE cur;
    DEALLOCATE cur;
END;
GO

CREATE TRIGGER trg_AutoGenerateMaChiTietHoaDon
ON ChiTietHoaDon
AFTER INSERT
AS
BEGIN
    -- Biến để lưu ID và mã chi tiết hóa đơn
    DECLARE @NewID INT, @NewMaChiTietHoaDon VARCHAR(20);

    -- Duyệt qua tất cả các bản ghi trong INSERTED
    DECLARE cur CURSOR FOR
    SELECT ID FROM INSERTED;

    OPEN cur;
    FETCH NEXT FROM cur INTO @NewID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Tạo mã chi tiết hóa đơn theo định dạng "CTHD" + ID (với 6 chữ số)
        SET @NewMaChiTietHoaDon = 'CTHD' + RIGHT('00' + CAST(@NewID AS VARCHAR(20)), 20);

        -- Cập nhật lại MaChiTietHoaDon trong bảng ChiTietHoaDon
        UPDATE ChiTietHoaDon
        SET MaChiTietHoaDon = @NewMaChiTietHoaDon
        WHERE ID = @NewID;

        FETCH NEXT FROM cur INTO @NewID;
    END;

    -- Đóng và giải phóng tài nguyên cursor
    CLOSE cur;
    DEALLOCATE cur;
END;
GO

-- Insert dữ liệu vào bảng Thể loại
INSERT INTO TheLoai (MaTheLoai, TenTheLoai) VALUES
('TL001', N'Tiểu thuyết'),
('TL002', N'Truyện tranh'),
('TL003', N'Kinh tế'),
('TL004', N'Khoa học'),
('TL005', N'Lịch sử');
GO

-- Insert dữ liệu vào bảng Ngôn Ngữ
INSERT INTO NgonNgu (MaNgonNgu, TenNgonNgu) VALUES
('NN001', N'Tiếng Việt'),
('NN002', N'Tiếng Anh'),
('NN003', N'Tiếng Nhật'),
('NN004', N'Tiếng Trung'),
('NN005', N'Tiếng Pháp');
GO

-- Insert dữ liệu vào bảng Chức vụ
INSERT INTO ChucVu (MaChucVu, TenChucVu) VALUES
('CV001', N'Quản lý'),
('CV002', N'Nhân viên'),
('CV003', N'Nhân viên'),
('CV004', N'Nhân viên'),
('CV005', N'Nhân viên');
GO

-- Insert dữ liệu vào bảng Nhà Xuất Bản
INSERT INTO NXB (MaNXB, TenNXB, DiaChi, SDT) VALUES
('NXB001', N'Nhà Xuất Bản Trẻ', N'123 Đường ABC, TP.HCM', '0123456789'),
('NXB002', N'Nhà Xuất Bản Kim Đồng', N'456 Đường XYZ, Hà Nội', '0987654321'),
('NXB003', N'Nhà Xuất Bản Giáo Dục', N'789 Đường DEF, Đà Nẵng', '0369852147'),
('NXB004', N'Nhà Xuất Bản Văn Học', N'321 Đường GHI, Cần Thơ', '0587412369'),
('NXB005', N'Nhà Xuất Bản Khoa Học', N'654 Đường KLM, Hải Phòng', '0741258963');
GO

-- Insert dữ liệu vào bảng Tác giả
INSERT INTO TacGia (MaTacGia, TenTacGia) VALUES
('TG001', N'Nguyễn Nhật Ánh'),
('TG002', N'J.K. Rowling'),
('TG003', N'Haruki Murakami'),
('TG004', N'Nguyễn Du'),
('TG005', N'Stephen King');
GO

-- Insert dữ liệu vào bảng Sản Phẩm 
INSERT INTO SanPham (MaSanPham, TenSanPham, GiaBan, HinhAnh, SoLuong, IDTheLoai, IDNgonNgu, IDNXB, IDTacGia) VALUES
('SP001', N'Cho tôi xin một vé đi tuổi thơ', 50000, 'image1.jpg', 100, 1, 1, 1, 1),
('SP002', N'Harry Potter và Hòn đá Phù thủy', 120000, 'image2.jpg', 50, 1, 2, 2, 2),
('SP003', N'Rừng Na Uy', 80000, 'image3.jpg', 75, 1, 3, 3, 3),
('SP004', N'Truyện Kiều', 30000, 'image4.jpg', 200, 5, 1, 4, 4),
('SP005', N'Thần đồng đất việt', 150000, 'image5.jpg', 30, 1, 2, 5, 5),
('SP006', N'Tắt đèn', 150000, 'image6.jpg', 50, 1, 1, 4, 4),
('SP007', N'Chí Phèo', 80000, 'image7.jpg', 30, 1, 1, 2, 1),
('SP008', N'Số đỏ', 120000, 'image8.jpg', 40, 1, 1, 3, 4),
('SP009', N'Tuổi thơ dữ dội', 90000, 'image9.jpg', 25, 1, 1, 4, 1),
('SP010', N'Tắt đèn', 100000, 'image10.jpg', 35, 1, 1, 5, 4),
('SP011', N'Vợ chồng A Phủ', 70000, 'image11.jpg', 20, 1, 1, 1, 1),
('SP012', N'A Tale of Two Cities', 200000, 'image12.jpg', 45, 1, 2, 2, 2),
('SP013', N'The Lord of the Rings', 250000, 'image13.jpg', 50, 1, 2, 3, 2),
('SP014', N'The Hobbit', 180000, 'image14.jpg', 30, 1, 2, 4, 2),
('SP015', N'Alice''s Adventures in Wonderland', 150000, 'image15.jpg', 25, 2, 2, 5, 5),
('SP016', N'The Cat in the Hat', 120000, 'image16.jpg', 35, 2, 2, 1, 5),
('SP017', N'To Kill a Mockingbird', 160000, 'image17.jpg', 40, 1, 2, 2, 5),
('SP018', N'Noruwei no mori', 220000, 'image18.jpg', 40, 1, 3, 3, 3),
('SP019', N'1Q84', 250000, 'image19.jpg', 35, 1, 3, 4, 3),
('SP020', N'Kinkaku-ji', 180000, 'image20.jpg', 20, 1, 3, 5, 3),
('SP021', N'Kitchen', 150000, 'image21.jpg', 25, 1, 3, 1, 3),
('SP022', N'Manen-gannen no futtobôru', 200000, 'image22.jpg', 30, 1, 3, 2, 3),
('SP023', N'Yukiguni', 160000, 'image23.jpg', 25, 1, 3, 3, 3),
('SP024', N'Kiếm lai', 190000, 'image24.jpg', 35, 1, 4, 4, 1),
('SP025', N'Tam quốc diễn nghĩa', 220000, 'image25.jpg', 40, 5, 4, 5, 4),
('SP026', N'Tây du kí', 180000, 'image26.jpg', 30, 2, 4, 1, 1),
('SP027', N'Hồng lâu mộng', 200000, 'image27.jpg', 25, 1, 4, 2, 4),
('SP028', N'Binh pháp tôn tử', 150000, 'image28.jpg', 35, 3, 4, 3, 1),
('SP029', N'Toàn chức cao thủ', 160000, 'image29.jpg', 20, 5, 4, 4, 1),
('SP030', N'Les Misérables', 250000, 'image30.jpg', 45, 1, 5, 5, 2),
('SP031', N'Le Petit Prince', 180000, 'image31.jpg', 30, 2, 5, 1, 5),
('SP032', N'Le Comte de Monte-Cristo', 220000, 'image32.jpg', 35, 1, 5, 2, 2),
('SP033', N'Les trois mousquetaires', 190000, 'image33.jpg', 25, 1, 5, 3, 5),
('SP034', N'Madam Bovary', 200000, 'image34.jpg', 30, 1, 5, 4, 2),
('SP035', N'L''Étranger', 170000, 'image35.jpg', 20, 1, 5, 5, 5);
GO

-- Insert dữ liệu vào bảng Nhân Viên
INSERT INTO NhanVien (MaNhanVien, TenNhanVien, MatKhau, SDT, GioiTinh, NgaySinh, IDChucVu,TrangThai) VALUES
('NV001', N'Nguyễn Văn Hùng', 'admin', '0123456789', 1, '1990-01-01', 1,1),
('NV002', N'Lê Thị Mai', 'password2', '0987654321', 0, '1997-04-10', 2,1),
('NV003', N'Hoàng Văn Tài', 'password3', '0369852147', 1, '2000-11-20', 3,0),
('NV004', N'Hoàng Thị Yến', 'password4', '0587412369', 0, '1999-07-30', 4,1),
('NV005', N'Hoàng Văn Long', 'password5', '0741258963', 1, '1993-03-25', 5,1),
('NV006', N'Trần Thị Linh', 'password6', '0979012345', 0, '2000-08-12', 2, 1);
GO

-- Insert dữ liệu vào bảng Khách Hàng (đã sửa email thành @gmail.com)
INSERT INTO KhachHang ( TenKhachHang, SDT, Email, GioiTinh, NgaySinh) VALUES
( N'Nguyễn Thị Hạnh', '0123456789', 'f.nguyen@gmail.com', 0, '1995-01-30'),
( N'Trần Văn Tâm', '0987654321', 'g.tran@gmail.com', 1, '1990-08-22'),
( N'Trần Thị Bích', '0369852147', 'h.le@gmail.com', 0, '1987-12-05'),
(N'Phạm Văn Bảo', '0587412369', 'i.pham@gmail.com', 1, '1992-06-18'),
(N'Nguyễn Thị Duyên', '0741258963', 'k.hoang@gmail.com', 0, '1994-09-30'),
(N'Hoàng Văn Minh', '0956789023', null, 1, '1987-06-30'),
(N'Nguyễn Hoa Anh', '0967890134', null, 0, '1994-09-05'),
(N'Trần Văn Khoa', '0978901245', 'khoa.tran@gmail.com', 1, '1991-12-15'),
(N'Lê Thị Ánh', '0989012356', null, 0, '1989-04-22'),
(N'Phạm Văn Hậu', '0990123467', null, 1, '1993-08-18'),
(N'Hoàng Thị Ngọc', '0901234578', null, 0, '1995-01-30'),
(N'Nguyễn Văn Đạt', '0913456890', 'dat.nguyen@gmail.com', 1, '1986-05-12');
GO

-- Insert dữ liệu vào bảng Phiếu Giảm Giá

INSERT INTO PhieuGiamGia (MaPhieuGiamGia, TenPhieuGiamGia, SoLuong, NgayBatDau, NgayKetThuc, SoTienGiam, TrangThai) VALUES
-- Tháng 1/2025
('PGG001', N'Ngày Đọc Sách Quốc Gia - Giảm 10K', 100, '2025-01-01', '2025-01-07', 10000, 0),  -- Hết hạn (trước 03/03/2025)
('PGG002', N'Tuần lễ Sách Mới - Giảm 15K', 80, '2025-01-08', '2025-01-14', 15000, 0),  -- Hết hạn (trước 03/03/2025)
('PGG003', N'Ngày Sách Đông - Giảm 20K', 60, '2025-01-15', '2025-01-21', 20000, 0),  -- Hết hạn (trước 03/03/2025)
('PGG004', N'Chào Năm Mới - Giảm 25K', 50, '2025-01-22', '2025-01-28', 25000, 0),  -- Hết hạn (trước 03/03/2025)
('PGG005', N'Ngày Sách Thiếu Nhi - Giảm 30K', 70, '2025-01-29', '2025-01-31', 30000, 0),  -- Hết hạn (trước 03/03/2025)

-- Tháng 2/2025
('PGG006', N'Ngày Valentine Sách - Giảm 15K', 90, '2025-02-01', '2025-02-14', 15000, 0),  -- Hết hạn (trước 03/03/2025)
('PGG007', N'Tuần lễ Văn Học - Giảm 20K', 75, '2025-02-15', '2025-02-21', 20000, 0),  -- Hết hạn (trước 03/03/2025)
('PGG008', N'Ngày Sách Lãng Mạn - Giảm 25K', 60, '2025-02-14', '2025-02-20', 25000, 0),  -- Hết hạn (trước 03/03/2025)
('PGG009', N'Kỷ niệm Sách Cổ - Giảm 10K', 100, '2025-02-21', '2025-02-28', 10000, 0),  -- Hết hạn (trước 03/03/2025)
('PGG010', N'Tháng Sách Ngắn - Giảm 30K', 50, '2025-02-22', '2025-02-28', 30000, 0),  -- Hết hạn (trước 03/03/2025)

-- Tháng 3/2025
('PGG011', N'Ngày Sách Khoa Học - Giảm 15K', 85, '2025-03-01', '2025-03-07', 15000, 1),  -- Còn hiệu lực (kết thúc sau 03/03/2025)
('PGG012', N'Tuần lễ Sách Lịch Sử - Giảm 20K', 70, '2025-03-08', '2025-03-14', 20000, 1),  -- Còn hiệu lực (kết thúc sau 03/03/2025)
('PGG013', N'Ngày Sách Quốc Tế - Giảm 25K', 60, '2025-03-15', '2025-03-21', 25000, 1),  -- Còn hiệu lực (kết thúc sau 03/03/2025)
('PGG014', N'Tháng Sách Mùa Xuân - Giảm 10K', 90, '2025-03-22', '2025-03-28', 10000, 1),  -- Còn hiệu lực (kết thúc sau 03/03/2025)
('PGG015', N'Ngày Hội Sách - Giảm 30K', 50, '2025-03-29', '2025-03-31', 30000, 1),  -- Còn hiệu lực (kết thúc sau 03/03/2025)
('PGG026', N'Sách Đặc Biệt 04/03 - Giảm 20K', 60, '2025-03-04', '2025-03-10', 20000, 1),  -- Còn hiệu lực (kết thúc sau 03/03/2025)
('PGG027', N'Khuyến Mãi Sách 04/03 - Giảm 25K', 50, '2025-03-04', '2025-03-09', 25000, 1);  -- Còn hiệu lực (kết thúc sau 03/03/2025)
GO



INSERT INTO HoaDon (IDNhanVien, IDKhachHang, IDPhieuGiamGia, TrangThai, TongTien, NgayTao) VALUES
-- Tháng 1/2025
(1, 1, 1, 1, 40000, '2025-01-01'),    -- IDKhachHang = 1
(2, 2, NULL, 1, 120000, '2025-01-02'), -- IDKhachHang = 2
(3, 3, 2, 1, 65000, '2025-01-10'),    -- IDKhachHang = 3
(4, 4, NULL, 1, 30000, '2025-01-12'), -- IDKhachHang = 4
(5, 5, 3, 1, 60000, '2025-01-16'),    -- IDKhachHang = 5
(6, 1, 4, 1, 25000, '2025-01-23'),    -- IDKhachHang = 1 (quay vòng)
(1, 2, 5, 1, 120000, '2025-01-30'),   -- IDKhachHang = 2
(2, 3, NULL, 1, 90000, '2025-01-31'), -- IDKhachHang = 3

-- Tháng 2/2025
(3, 4, 6, 1, 135000, '2025-02-05'),   -- IDKhachHang = 4
(4, 5, NULL, 1, 70000, '2025-02-10'), -- IDKhachHang = 5
(5, 1, 8, 1, 95000, '2025-02-15'),    -- IDKhachHang = 1
(6, 2, 7, 1, 60000, '2025-02-16'),    -- IDKhachHang = 2
(1, 3, 9, 1, 40000, '2025-02-22'),    -- IDKhachHang = 3
(2, 4, 10, 1, 120000, '2025-02-25'),  -- IDKhachHang = 4
(3, 5, NULL, 1, 160000, '2025-02-28'), -- IDKhachHang = 5

-- Tháng 3/2025
(4, 1, 11, 1, 65000, '2025-03-01'),   -- IDKhachHang = 1
(5, 2, NULL, 1, 30000, '2025-03-02'), -- IDKhachHang = 2
(6, 3, NULL, 1, 200000, '2025-03-02'), -- IDKhachHang = 3
(1, 4, 16, 1, 180000, '2025-03-03'),  -- IDKhachHang = 4 (sửa từ 26 thành 16)
(2, 5, 17, 1, 225000, '2025-03-03');  -- IDKhachHang = 5 (sửa từ 27 thành 17)
GO

-- Insert dữ liệu vào bảng Chi Tiết Hóa Đơn
INSERT INTO ChiTietHoaDon (IDHoaDon, IDSanPham, SoLuong) VALUES
-- Hóa đơn 1 (01/01/2025): 50K - 10K = 40K
(1, 1, 1),  -- SP001: 50K, SL: 1

-- Hóa đơn 2 (02/01/2025): 120K
(2, 2, 1),  -- SP002: 120K, SL: 1

-- Hóa đơn 3 (10/01/2025): 80K - 15K = 65K
(3, 3, 1),  -- SP003: 80K, SL: 1

-- Hóa đơn 4 (12/01/2025): 30K
(4, 4, 1),  -- SP004: 30K, SL: 1

-- Hóa đơn 5 (16/01/2025): 80K - 20K = 60K
(5, 3, 1),  -- SP003: 80K, SL: 1

-- Hóa đơn 6 (23/01/2025): 50K - 25K = 25K
(6, 1, 1),  -- SP001: 50K, SL: 1

-- Hóa đơn 7 (30/01/2025): 150K - 30K = 120K
(7, 5, 1),  -- SP005: 150K, SL: 1

-- Hóa đơn 8 (31/01/2025): 90K
(8, 9, 1),  -- SP009: 90K, SL: 1

-- Hóa đơn 9 (05/02/2025): 150K - 15K = 135K
(9, 5, 1),  -- SP005: 150K, SL: 1

-- Hóa đơn 10 (10/02/2025): 70K
(10, 11, 1), -- SP011: 70K, SL: 1

-- Hóa đơn 11 (15/02/2025): 120K - 25K = 95K
(11, 2, 1), -- SP002: 120K, SL: 1

-- Hóa đơn 12 (16/02/2025): 80K - 20K = 60K
(12, 3, 1), -- SP003: 80K, SL: 1

-- Hóa đơn 13 (22/02/2025): 50K - 10K = 40K
(13, 1, 1), -- SP001: 50K, SL: 1

-- Hóa đơn 14 (25/02/2025): 150K - 30K = 120K
(14, 5, 1), -- SP005: 150K, SL: 1

-- Hóa đơn 15 (28/02/2025): 160K
(15, 17, 1), -- SP017: 160K, SL: 1

-- Hóa đơn 16 (01/03/2025): 80K - 15K = 65K
(16, 3, 1), -- SP003: 80K, SL: 1

-- Hóa đơn 17 (02/03/2025): 30K
(17, 4, 1), -- SP004: 30K, SL: 1

-- Hóa đơn 18 (02/03/2025): 200K
(18, 13, 1), -- SP013: 200K, SL: 1

-- Hóa đơn 19 (03/03/2025): 200K - 20K = 180K
(19, 12, 1), -- SP012: 200K, SL: 1

-- Hóa đơn 20 (03/03/2025): 250K - 25K = 225K
(20, 13, 1); -- SP013: 250K, SL: 1
GO


SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'CK__HoaDon__TongTien__693CA210';

go

Alter table TacGia
add TrangThai bit
Alter table NXB
add TrangThai bit


