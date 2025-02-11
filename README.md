# Salesbook App

This Flutter application is designed to replace a traditional paper salesbook, providing a convenient and efficient way to manage clients, sales, and payments.  It offers a user-friendly interface for tracking financial information and generating insightful charts.

## Features

*   **Clients List:**
    *   Displays all clients in alphabetical order.
    *   Provides options to add, edit, and remove clients.
*   **Client Details:**
    *   Displays detailed information for each client, including:
        *   Name
        *   Address
        *   Personal Number
        *   NFC-e (Bill) display
        *   Payment button
*   **NFC-e (Bill) Display:**
    *   Shows a client's bill details, including:
        *   Bill Description
        *   Date
        *   Value
*   **Payment:**
    *   Redirects to a payment screen where the total amount due can be paid, reflecting the remaining debit or credit.
*   **Sales Screen:**
    *   Allows users to record sales with the following information:
        *   Client Selection
        *   Date Selection
        *   Total Sale Value
        *   Description
*   **Charts Screen:**
    *   Visualizes sales and payment data through charts.
    *   Allows users to select a period range (week, month, year) for data analysis.
*   **Settings Screen:**
    *   Provides backup and restore functionality using Google Drive.
        *   Export data to Google Drive.
        *   Import data from Google Drive.

## Technology Stack

*   **Flutter:** The primary framework for building the app.
*   **sqflite:** A Flutter package used for local database storage.
*   **Google Drive API:** Enabled for the backup and restore functionality.  Requires a Google Cloud Console project and enabling the Google Drive API.
