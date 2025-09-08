package com.example.attendance.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {
    private static final String URL = "jdbc:mysql://localhost:3306/your_database_name?serverTimezone=UTC";
    private static final String USER = "your_db_user";
    private static final String PASSWORD = "your_db_password";

    public Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
