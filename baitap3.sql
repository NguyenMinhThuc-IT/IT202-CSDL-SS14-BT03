USE RikkeiClinic_SS14_BT01_DB;

DROP PROCEDURE IF EXISTS DispenseMedicine;

DELIMITER //

CREATE PROCEDURE DispenseMedicine(
    IN p_patient_id INT,
    IN p_medicine_id INT,
    IN p_quantity INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    -- Khai báo các biến cục bộ hỗ trợ tính toán nội bộ
    DECLARE v_current_stock INT;
    DECLARE v_medicine_price DECIMAL(18,2);
    DECLARE v_total_cost DECIMAL(18,2);
   
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Hệ thống lỗi: Giao dịch đã được hoàn tác an toàn.';
    END;

    START TRANSACTION;

    SELECT stock, price INTO v_current_stock, v_medicine_price
    FROM Medicines
    WHERE medicine_id = p_medicine_id;

    IF v_current_stock IS NULL THEN
        BEGIN
            ROLLBACK;
            SET p_message = 'Lỗi: Mã thuốc không tồn tại trên hệ thống.';
        END;
        
    ELSEIF p_quantity <= 0 THEN
        BEGIN
            ROLLBACK;
            SET p_message = 'Lỗi: Số lượng cấp phát phải lớn hơn 0.';
        END;
        
    ELSEIF p_quantity > v_current_stock THEN
        BEGIN
            ROLLBACK;
            SET p_message = 'Lỗi: Số lượng tồn kho không đủ';
        END;
        
    ELSE
        BEGIN
	
            UPDATE Medicines
            SET stock = stock - p_quantity
            WHERE medicine_id = p_medicine_id;

            SET v_total_cost = p_quantity * v_medicine_price;
            
            UPDATE Patient_Invoices
            SET total_due = total_due + v_total_cost
            WHERE patient_id = p_patient_id;

            COMMIT;
            SET p_message = 'Đã cấp phát thành công';
        END;
    END IF;

END //

DELIMITER ;

SET @test_output_msg = '';

CALL DispenseMedicine(1, 2, 2, @test_output_msg);

-- Xem thông báo hiển thị trên màn hình ứng dụng
SELECT @test_output_msg AS 'Thông báo từ hệ thống (Case 1)'; 

-- Truy vấn đối chiếu để xác minh dữ liệu đã lưu xuống đĩa cứng:
SELECT * FROM Medicines WHERE medicine_id = 2;       
SELECT * FROM Patient_Invoices WHERE patient_id = 1; 

CALL DispenseMedicine(2, 2, 10, @test_output_msg);

SELECT @test_output_msg AS 'Thông báo từ hệ thống (Case 2)'; 

SELECT * FROM Medicines WHERE medicine_id = 2;       
SELECT * FROM Patient_Invoices WHERE patient_id = 2;