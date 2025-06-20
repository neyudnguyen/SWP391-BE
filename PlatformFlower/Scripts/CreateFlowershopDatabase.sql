-- Kiểm tra và xóa database Flowershop nếu tồn tại
IF DB_ID('Flowershop') IS NOT NULL
    DROP DATABASE Flowershop;
GO

-- Tạo mới database Flowershop
CREATE DATABASE Flowershop;
GO

-- Sử dụng database Flowershop
USE Flowershop;
GO

-- Bảng Users với username là unique và các trường reset password
CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username NVARCHAR(255) NOT NULL UNIQUE,  -- Username phải là duy nhất
    password NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) NOT NULL,
    type NVARCHAR(20) NOT NULL,
    created_date DATETIME DEFAULT GETDATE(),
    status NVARCHAR(20) DEFAULT 'active',
    reset_password_token NVARCHAR(255) NULL,  -- Token để reset password
    reset_password_token_expiry DATETIME NULL,  -- Thời gian hết hạn của token
    CONSTRAINT chk_role CHECK (type IN ('admin', 'seller', 'user')),
    CONSTRAINT chk_status CHECK (status IN ('active', 'inactive'))
);
GO

CREATE TABLE Seller (
    seller_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    shop_name NVARCHAR(255) NOT NULL,
    address_seller NVARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    total_product INT DEFAULT 0,
    role NVARCHAR(20) NOT NULL CHECK (role IN ('individual', 'enterprise')),
    introduction TEXT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Bảng User_Info
CREATE TABLE User_Info (
    user_info_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT,
    address NVARCHAR(255),
    full_name NVARCHAR(255),
    birth_date DATE,
    sex NVARCHAR(10),
    is_seller BIT DEFAULT 0,  -- Boolean thay bằng BIT
    avatar NVARCHAR(255),
    created_date DATETIME DEFAULT GETDATE(),
    updated_date DATETIME DEFAULT GETDATE(),
    Points INT CONSTRAINT DF_User_Info_Points DEFAULT 100,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT chk_sex CHECK (sex IN ('male', 'female', 'other'))
);
GO

-- Bảng Category cho các loại hoa
CREATE TABLE Category (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    category_name NVARCHAR(255) NOT NULL,
    status NVARCHAR(20) DEFAULT 'active',
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT chk_category_status CHECK (status IN ('active', 'inactive'))
);
GO

-- Bảng Flower_Info với liên kết đến bảng Category và Seller
CREATE TABLE Flower_Info (
    flower_id INT IDENTITY(1,1) PRIMARY KEY,
    flower_name NVARCHAR(255) NOT NULL,
    flower_description NVARCHAR(255),
    price DECIMAL(10, 2) NOT NULL,
    image_url NVARCHAR(255),
    available_quantity INT NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    category_id INT,
    seller_id INT,
    FOREIGN KEY (category_id) REFERENCES Category(category_id),
    FOREIGN KEY (seller_id) REFERENCES Seller(seller_id)
);
GO

-- Bảng Cart chỉ cho phép người dùng 'user'
CREATE TABLE Cart (
    cart_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT,
    flower_id INT,
    quantity INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (flower_id) REFERENCES Flower_Info(flower_id)
);
GO

-- Bảng Address
CREATE TABLE Address (
address_id INT IDENTITY(1,1) PRIMARY KEY,
    user_info_id INT,
    description NVARCHAR(255),
    FOREIGN KEY (user_info_id) REFERENCES User_Info(user_info_id)
);
GO

-- Bảng User_Voucher_Status
CREATE TABLE User_Voucher_Status (
    user_voucher_status_id INT IDENTITY(1,1) PRIMARY KEY,
    user_info_id INT,                       -- Liên kết tới người dùng
    voucher_code NVARCHAR(50) NOT NULL,     -- Mã voucher
    discount FLOAT NOT NULL,                -- Phần trăm/giá trị giảm giá của voucher
    description NVARCHAR(255),              -- Mô tả voucher
    start_date DATETIME NOT NULL,           -- Ngày bắt đầu của voucher
    end_date DATETIME NOT NULL,             -- Ngày kết thúc của voucher
    usage_limit INT,                        -- Giới hạn số lần sử dụng của voucher
    usage_count INT DEFAULT 0,              -- Số lần voucher đã được sử dụng bởi người dùng này
    remaining_count INT,                    -- Số lượng voucher còn lại cho người dùng
    created_at DATETIME DEFAULT GETDATE(),  -- Thời gian tạo voucher
    shop_id INT,
    FOREIGN KEY (user_info_id) REFERENCES User_Info(user_info_id),
    FOREIGN KEY (shop_id) REFERENCES Seller(seller_id)
);
GO

-- Bảng Orders
CREATE TABLE Orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT,
    phone_number NVARCHAR(20),
    payment_method NVARCHAR(50) NOT NULL,
    delivery_method NVARCHAR(255) NOT NULL,
    created_date DATETIME DEFAULT GETDATE(),
    user_voucher_status_id INT,
    address_id INT,
    cart_id INT,
    status_payment NVARCHAR(20),
    total_price DECIMAL(10, 2),  -- Tổng giá trị của đơn hàng
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (user_voucher_status_id) REFERENCES User_Voucher_Status(user_voucher_status_id),
    FOREIGN KEY (address_id) REFERENCES Address(address_id),
    FOREIGN KEY (cart_id) REFERENCES Cart(cart_id)
);
GO

-- Bảng Orders_Detail
CREATE TABLE Orders_Detail (
    order_detail_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT,
    seller_id INT,
    flower_id INT,
    price DECIMAL(10, 2) NOT NULL,
    amount INT NOT NULL,
    user_voucher_status_id INT,
    status NVARCHAR(20) DEFAULT 'pending',
    created_at DATETIME DEFAULT GETDATE(),
    address_id INT,
    delivery_method NVARCHAR(255) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (flower_id) REFERENCES Flower_Info(flower_id),
    FOREIGN KEY (seller_id) REFERENCES Seller(seller_id),
    FOREIGN KEY (address_id) REFERENCES Address(address_id),
    FOREIGN KEY (user_voucher_status_id) REFERENCES User_Voucher_Status(user_voucher_status_id),
    CONSTRAINT chk_order_detail_status CHECK (status IN ('pending', 'delivered', 'canceled','accepted','pending delivery'))
);
GO

-- Bảng Product_Report để lưu thông tin báo cáo sản phẩm
CREATE TABLE Report (
report_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,  -- Người dùng báo cáo
    flower_id INT NOT NULL,  -- Sản phẩm bị báo cáo
    seller_id INT NOT NULL,  -- Người bán sản phẩm bị báo cáo
    report_reason NVARCHAR(255) NOT NULL,  -- Lý do báo cáo
    report_description NVARCHAR(255),  -- Mô tả chi tiết về báo cáo
    status NVARCHAR(20) DEFAULT 'pending',  -- Trạng thái xử lý báo cáo
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (flower_id) REFERENCES Flower_Info(flower_id),
    FOREIGN KEY (seller_id) REFERENCES Seller(seller_id),
    CONSTRAINT chk_report_status CHECK (status IN ('pending', 'resolved', 'dismissed'))  -- Ràng buộc trạng thái
);
GO

PRINT 'Database Flowershop created successfully with password reset functionality!';
