-- ra7-media table (created automatically on start; this file is for manual installs)
CREATE TABLE IF NOT EXISTS ra7_media (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kind VARCHAR(16) NOT NULL,
    data LONGTEXT NOT NULL,
    updated_by VARCHAR(64) NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
