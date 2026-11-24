-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 24, 2026 at 08:27 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `zero waste resturant surplus & donation network`
--

-- --------------------------------------------------------

--
-- Table structure for table `accesslog`
--

CREATE TABLE `accesslog` (
  `log_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `login_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `logout_time` timestamp NULL DEFAULT NULL,
  `session_status` enum('Success','Failed','Active','Closed') DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `accesslog`
--

INSERT INTO `accesslog` (`log_id`, `user_id`, `ip_address`, `login_time`, `logout_time`, `session_status`) VALUES
(1, 1, '192.168.0.101', '2026-11-24 07:18:28', NULL, 'Active'),
(2, 2, '192.168.0.105', '2026-11-24 07:18:28', NULL, 'Active'),
(3, 4, '192.168.0.112', '2026-11-24 07:18:28', NULL, 'Success');

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `admin_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `designation` varchar(50) DEFAULT NULL,
  `clearance_level` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admin`
--

INSERT INTO `admin` (`admin_id`, `user_id`, `full_name`, `designation`, `clearance_level`) VALUES
(1, 1, 'Rajiur Rahman', 'System Operations Lead', 3);

-- --------------------------------------------------------

--
-- Table structure for table `allergentag`
--

CREATE TABLE `allergentag` (
  `allergen_id` int(11) NOT NULL,
  `allergen_name` varchar(50) NOT NULL,
  `severity_note` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `allergentag`
--

INSERT INTO `allergentag` (`allergen_id`, `allergen_name`, `severity_note`) VALUES
(1, 'Peanuts & Tree Nuts', 'Severe allergy risk in Biryani/Korma'),
(2, 'Dairy / Ghee', 'Contains milk solids and butter oil'),
(3, 'Shellfish / Prawn', 'High allergen warning');

-- --------------------------------------------------------

--
-- Table structure for table `auditlog`
--

CREATE TABLE `auditlog` (
  `audit_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `action_type` varchar(50) NOT NULL,
  `target_table` varchar(50) NOT NULL,
  `record_id` int(11) NOT NULL,
  `action_details` text DEFAULT NULL,
  `action_timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `auditlog`
--

INSERT INTO `auditlog` (`audit_id`, `user_id`, `action_type`, `target_table`, `record_id`, `action_details`, `action_timestamp`) VALUES
(1, 1, 'VERIFY_DONOR', 'DonorOrganization', 1, 'Verified trade license for Kacchi Bhai GEC', '2026-11-24 07:18:29'),
(2, NULL, 'FOOD_CLAIMED', 'SurplusListing', 1, 'Claim ID #1 locked listing #1', '2026-11-24 07:18:34'),
(3, NULL, 'FOOD_CLAIMED', 'SurplusListing', 2, 'Claim ID #2 locked listing #2', '2026-11-24 07:18:34');

-- --------------------------------------------------------

--
-- Table structure for table `claimrequest`
--

CREATE TABLE `claimrequest` (
  `claim_id` int(11) NOT NULL,
  `listing_id` int(11) NOT NULL,
  `receiver_id` int(11) NOT NULL,
  `requested_servings` int(11) NOT NULL,
  `claim_status` enum('Pending','Approved','Picked_Up','Completed','Cancelled') DEFAULT 'Approved',
  `verification_otp` varchar(10) NOT NULL,
  `claimed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `claimrequest`
--

INSERT INTO `claimrequest` (`claim_id`, `listing_id`, `receiver_id`, `requested_servings`, `claim_status`, `verification_otp`, `claimed_at`) VALUES
(1, 1, 1, 40, 'Approved', 'OTP-8492', '2026-11-24 07:18:34'),
(2, 2, 2, 30, 'Completed', 'OTP-3910', '2026-11-24 07:18:34');

--
-- Triggers `claimrequest`
--
DELIMITER $$
CREATE TRIGGER `trg_after_claim_insert` AFTER INSERT ON `claimrequest` FOR EACH ROW BEGIN
    UPDATE SurplusListing 
    SET listing_status = 'Claimed' 
    WHERE listing_id = NEW.listing_id;

    INSERT INTO AuditLog (action_type, target_table, record_id, action_details)
    VALUES ('FOOD_CLAIMED', 'SurplusListing', NEW.listing_id, 
            CONCAT('Claim ID #', NEW.claim_id, ' locked listing #', NEW.listing_id));
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `deliveryroutelog`
--

CREATE TABLE `deliveryroutelog` (
  `route_log_id` int(11) NOT NULL,
  `assignment_id` int(11) NOT NULL,
  `checkpoint_name` varchar(100) NOT NULL,
  `current_temp_celsius` decimal(4,1) DEFAULT NULL,
  `logged_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `deliveryroutelog`
--

INSERT INTO `deliveryroutelog` (`route_log_id`, `assignment_id`, `checkpoint_name`, `current_temp_celsius`, `logged_at`) VALUES
(1, 1, 'Picked up from Kacchi Bhai GEC', 66.0, '2026-11-24 07:18:35'),
(2, 1, 'Crossing Probartak Mor', 64.5, '2026-11-24 07:18:35'),
(3, 2, 'Delivered at Protyasha Shelter, Halishahar', 62.0, '2026-11-24 07:18:35');

-- --------------------------------------------------------

--
-- Table structure for table `donororganization`
--

CREATE TABLE `donororganization` (
  `donor_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `zone_id` int(11) NOT NULL,
  `org_name` varchar(150) NOT NULL,
  `org_type` enum('Restaurant','Hotel','Convention Hall','Bakery','Catering') NOT NULL,
  `trade_license_no` varchar(50) NOT NULL,
  `address` text NOT NULL,
  `hygiene_rating` decimal(3,2) DEFAULT 5.00,
  `is_verified` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `donororganization`
--

INSERT INTO `donororganization` (`donor_id`, `user_id`, `zone_id`, `org_name`, `org_type`, `trade_license_no`, `address`, `hygiene_rating`, `is_verified`) VALUES
(1, 2, 1, 'Kacchi Bhai - GEC Branch', 'Restaurant', 'TL-CTG-2026-101', 'GEC Circle, CDA Avenue, Chattogram', 4.95, 1),
(2, 3, 2, 'Handi Restaurant', 'Restaurant', 'TL-CTG-2026-102', 'Sheikh Mujib Road, Agrabad, Chattogram', 4.85, 1);

-- --------------------------------------------------------

--
-- Table structure for table `feedbackrating`
--

CREATE TABLE `feedbackrating` (
  `feedback_id` int(11) NOT NULL,
  `claim_id` int(11) NOT NULL,
  `receiver_id` int(11) NOT NULL,
  `food_quality_score` int(11) DEFAULT NULL CHECK (`food_quality_score` between 1 and 5),
  `delivery_speed_score` int(11) DEFAULT NULL CHECK (`delivery_speed_score` between 1 and 5),
  `comments` text DEFAULT NULL,
  `submitted_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `feedbackrating`
--

INSERT INTO `feedbackrating` (`feedback_id`, `claim_id`, `receiver_id`, `food_quality_score`, `delivery_speed_score`, `comments`, `submitted_at`) VALUES
(1, 2, 2, 5, 5, 'Food arrived warm and fresh! Children loved it.', '2026-11-24 07:18:35');

-- --------------------------------------------------------

--
-- Table structure for table `foodcategory`
--

CREATE TABLE `foodcategory` (
  `category_id` int(11) NOT NULL,
  `category_name` varchar(100) NOT NULL,
  `storage_type` enum('Hot','Chilled','Frozen','Room Temp') NOT NULL,
  `max_shelf_life_hours` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `foodcategory`
--

INSERT INTO `foodcategory` (`category_id`, `category_name`, `storage_type`, `max_shelf_life_hours`) VALUES
(1, 'Cooked Rice & Biryani', 'Hot', 6),
(2, 'Curry & Protein', 'Hot', 5),
(3, 'Bakery & Pastries', 'Room Temp', 24);

-- --------------------------------------------------------

--
-- Table structure for table `impactmetric`
--

CREATE TABLE `impactmetric` (
  `metric_id` int(11) NOT NULL,
  `donor_id` int(11) NOT NULL,
  `total_meals_donated` int(11) DEFAULT 0,
  `total_food_saved_kg` decimal(10,2) DEFAULT 0.00,
  `co2_offset_kg` decimal(10,2) DEFAULT 0.00,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `impactmetric`
--

INSERT INTO `impactmetric` (`metric_id`, `donor_id`, `total_meals_donated`, `total_food_saved_kg`, `co2_offset_kg`, `last_updated`) VALUES
(1, 1, 150, 75.00, 187.50, '2026-11-24 07:18:33'),
(2, 2, 120, 60.00, 150.00, '2026-11-24 07:18:35');

-- --------------------------------------------------------

--
-- Table structure for table `incidentreport`
--

CREATE TABLE `incidentreport` (
  `incident_id` int(11) NOT NULL,
  `listing_id` int(11) NOT NULL,
  `reported_by_user` int(11) NOT NULL,
  `incident_type` enum('Food Spoiled','Late Pickup','Packaging Damaged','Wrong Quantity') NOT NULL,
  `severity` enum('Low','Medium','Critical') DEFAULT 'Medium',
  `resolution_status` enum('Open','Investigating','Resolved') DEFAULT 'Open',
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `incidentreport`
--

INSERT INTO `incidentreport` (`incident_id`, `listing_id`, `reported_by_user`, `incident_type`, `severity`, `resolution_status`, `description`, `created_at`) VALUES
(1, 3, 2, 'Packaging Damaged', 'Low', 'Resolved', 'Minor foil tear replaced before dispatch.', '2026-11-24 07:18:35');

-- --------------------------------------------------------

--
-- Table structure for table `listingallergenmap`
--

CREATE TABLE `listingallergenmap` (
  `listing_id` int(11) NOT NULL,
  `allergen_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `listingallergenmap`
--

INSERT INTO `listingallergenmap` (`listing_id`, `allergen_id`) VALUES
(1, 1),
(1, 2),
(2, 2);

-- --------------------------------------------------------

--
-- Table structure for table `locationzone`
--

CREATE TABLE `locationzone` (
  `zone_id` int(11) NOT NULL,
  `zone_name` varchar(100) NOT NULL,
  `city` varchar(50) DEFAULT 'Chattogram',
  `postal_code` varchar(20) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `locationzone`
--

INSERT INTO `locationzone` (`zone_id`, `zone_name`, `city`, `postal_code`, `latitude`, `longitude`) VALUES
(1, 'GEC Circle', 'Chattogram', '4000', 22.35910000, 91.82150000),
(2, 'Agrabad Commercial Area', 'Chattogram', '4100', 22.32380000, 91.81230000),
(3, 'Halishahar Housing Estate', 'Chattogram', '4216', 22.33890000, 91.78120000),
(4, 'Panchlaish Residential Area', 'Chattogram', '4203', 22.36540000, 91.83210000);

-- --------------------------------------------------------

--
-- Table structure for table `notificationalert`
--

CREATE TABLE `notificationalert` (
  `alert_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `alert_title` varchar(150) NOT NULL,
  `alert_message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notificationalert`
--

INSERT INTO `notificationalert` (`alert_id`, `user_id`, `alert_title`, `alert_message`, `is_read`, `created_at`) VALUES
(1, 4, 'Claim Approved', 'Your claim for 40 servings of Basmati Kacchi Biryani is approved. OTP: OTP-8492', 0, '2026-11-24 07:18:35'),
(2, 6, 'Pickup In Transit', 'Delivering to Al-Amin Shishu Sadan, Panchlaish.', 0, '2026-11-24 07:18:35');

-- --------------------------------------------------------

--
-- Table structure for table `pickupassignment`
--

CREATE TABLE `pickupassignment` (
  `assignment_id` int(11) NOT NULL,
  `claim_id` int(11) NOT NULL,
  `volunteer_id` int(11) NOT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `picked_up_at` datetime DEFAULT NULL,
  `delivered_at` datetime DEFAULT NULL,
  `dispatch_status` enum('Assigned','Picked_Up','In_Transit','Delivered','Failed') DEFAULT 'Assigned'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pickupassignment`
--

INSERT INTO `pickupassignment` (`assignment_id`, `claim_id`, `volunteer_id`, `assigned_at`, `picked_up_at`, `delivered_at`, `dispatch_status`) VALUES
(1, 1, 1, '2026-11-24 07:18:34', '2026-11-24 13:03:34', NULL, 'In_Transit'),
(2, 2, 2, '2026-11-24 07:18:34', '2026-11-24 12:38:34', '2026-11-24 13:18:35', 'Delivered');

--
-- Triggers `pickupassignment`
--
DELIMITER $$
CREATE TRIGGER `trg_after_delivery_complete` AFTER UPDATE ON `pickupassignment` FOR EACH ROW BEGIN
    DECLARE v_listing_id INT;
    DECLARE v_donor_id INT;
    DECLARE v_servings INT;
    DECLARE v_weight DECIMAL(6,2);

    IF NEW.dispatch_status = 'Delivered' AND OLD.dispatch_status != 'Delivered' THEN
        SELECT c.listing_id, s.donor_id, s.quantity_servings, s.estimated_weight_kg
        INTO v_listing_id, v_donor_id, v_servings, v_weight
        FROM ClaimRequest c
        JOIN SurplusListing s ON c.listing_id = s.listing_id
        WHERE c.claim_id = NEW.claim_id;

        UPDATE SurplusListing SET listing_status = 'Delivered' WHERE listing_id = v_listing_id;
        UPDATE ClaimRequest SET claim_status = 'Completed' WHERE claim_id = NEW.claim_id;
        UPDATE Volunteer SET availability_status = 'Available', total_deliveries = total_deliveries + 1 
        WHERE volunteer_id = NEW.volunteer_id;

        UPDATE ImpactMetric 
        SET total_meals_donated = total_meals_donated + v_servings,
            total_food_saved_kg = total_food_saved_kg + v_weight,
            co2_offset_kg = co2_offset_kg + (v_weight * 2.5)
        WHERE donor_id = v_donor_id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `receiverorganization`
--

CREATE TABLE `receiverorganization` (
  `receiver_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `zone_id` int(11) NOT NULL,
  `org_name` varchar(150) NOT NULL,
  `reg_number` varchar(50) NOT NULL,
  `daily_headcount` int(11) NOT NULL CHECK (`daily_headcount` > 0),
  `address` text NOT NULL,
  `priority_level` enum('High','Medium','Normal') DEFAULT 'Normal'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `receiverorganization`
--

INSERT INTO `receiverorganization` (`receiver_id`, `user_id`, `zone_id`, `org_name`, `reg_number`, `daily_headcount`, `address`, `priority_level`) VALUES
(1, 4, 4, 'Al-Amin Shishu Sadan', 'DSS-CTG-501', 85, 'Road 4, Panchlaish, Chattogram', 'High'),
(2, 5, 3, 'Protyasha Street Children Shelter', 'DSS-CTG-502', 50, 'Block-G, Halishahar, Chattogram', 'Medium');

-- --------------------------------------------------------

--
-- Table structure for table `safetyinspection`
--

CREATE TABLE `safetyinspection` (
  `inspection_id` int(11) NOT NULL,
  `listing_id` int(11) NOT NULL,
  `inspector_name` varchar(100) NOT NULL,
  `food_temp_celsius` decimal(4,1) NOT NULL,
  `packaging_intact` tinyint(1) DEFAULT 1,
  `safety_status` enum('Passed','Rejected') DEFAULT 'Passed',
  `inspected_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `safetyinspection`
--

INSERT INTO `safetyinspection` (`inspection_id`, `listing_id`, `inspector_name`, `food_temp_celsius`, `packaging_intact`, `safety_status`, `inspected_at`) VALUES
(1, 1, 'Chef Kamal Uddin', 68.5, 1, 'Passed', '2026-11-24 07:18:34'),
(2, 2, 'Manager Sajib', 65.0, 1, 'Passed', '2026-11-24 07:18:34');

-- --------------------------------------------------------

--
-- Table structure for table `surpluslisting`
--

CREATE TABLE `surpluslisting` (
  `listing_id` int(11) NOT NULL,
  `donor_id` int(11) NOT NULL,
  `category_id` int(11) NOT NULL,
  `food_title` varchar(150) NOT NULL,
  `quantity_servings` int(11) NOT NULL CHECK (`quantity_servings` >= 0),
  `estimated_weight_kg` decimal(6,2) NOT NULL,
  `cooked_time` datetime NOT NULL,
  `expiry_time` datetime NOT NULL,
  `pickup_window_end` datetime NOT NULL,
  `listing_status` enum('Available','Claimed','In_Transit','Delivered','Expired') DEFAULT 'Available',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `surpluslisting`
--

INSERT INTO `surpluslisting` (`listing_id`, `donor_id`, `category_id`, `food_title`, `quantity_servings`, `estimated_weight_kg`, `cooked_time`, `expiry_time`, `pickup_window_end`, `listing_status`, `created_at`) VALUES
(1, 1, 1, 'Basmati Kacchi Biryani (Fresh Surplus)', 40, 20.00, '2026-11-24 12:18:33', '2026-11-24 17:18:33', '2026-11-24 15:18:33', 'Claimed', '2026-11-24 07:18:33'),
(2, 2, 2, 'Chicken Roast & Plain Polao', 30, 15.00, '2026-11-24 11:18:33', '2026-11-24 16:18:33', '2026-11-24 14:18:33', 'Delivered', '2026-11-24 07:18:33'),
(3, 1, 3, 'Assorted Evening Snacks & Naan', 25, 8.50, '2026-11-24 12:48:33', '2026-11-24 21:18:33', '2026-11-24 16:18:33', 'Available', '2026-11-24 07:18:33');

-- --------------------------------------------------------

--
-- Table structure for table `useraccount`
--

CREATE TABLE `useraccount` (
  `user_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `user_role` enum('Admin','Donor','Receiver','Volunteer') NOT NULL,
  `account_status` enum('Pending','Active','Suspended') DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `useraccount`
--

INSERT INTO `useraccount` (`user_id`, `username`, `email`, `password_hash`, `phone`, `user_role`, `account_status`, `created_at`) VALUES
(1, 'admin_ctg', 'admin@zerowaste.org', 'hash_admin_123', '01811000001', 'Admin', 'Active', '2026-11-24 07:18:27'),
(2, 'kacchi_bhai_gec', 'gec@kacchibhai.com', 'hash_donor_101', '01811000002', 'Donor', 'Active', '2026-11-24 07:18:27'),
(3, 'handi_agrabad', 'agrabad@handictg.com', 'hash_donor_102', '01811000003', 'Donor', 'Active', '2026-11-24 07:18:27'),
(4, 'al_amin_orphanage', 'contact@alaminsadan.org', 'hash_recv_201', '01811000004', 'Receiver', 'Active', '2026-11-24 07:18:27'),
(5, 'protyasha_shelter', 'info@protyashactg.org', 'hash_recv_202', '01811000005', 'Receiver', 'Active', '2026-11-24 07:18:27'),
(6, 'rafiq_rider', 'rafiq.vol@gmail.com', 'hash_vol_301', '01811000006', 'Volunteer', 'Active', '2026-11-24 07:18:27'),
(7, 'tanvir_vol', 'tanvir.vol@gmail.com', 'hash_vol_302', '01811000007', 'Volunteer', 'Active', '2026-11-24 07:18:27');

-- --------------------------------------------------------

--
-- Table structure for table `volunteer`
--

CREATE TABLE `volunteer` (
  `volunteer_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `zone_id` int(11) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `nid_number` varchar(30) NOT NULL,
  `vehicle_type` enum('Bicycle','Motorcycle','Van','Refrigerated Van') NOT NULL,
  `availability_status` enum('Available','Busy','Offline') DEFAULT 'Available',
  `total_deliveries` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `volunteer`
--

INSERT INTO `volunteer` (`volunteer_id`, `user_id`, `zone_id`, `full_name`, `nid_number`, `vehicle_type`, `availability_status`, `total_deliveries`) VALUES
(1, 6, 1, 'Rafiqul Islam', '1999152410341', 'Motorcycle', 'Busy', 14),
(2, 7, 2, 'Tanvir Ahmed', '2000152410342', 'Bicycle', 'Available', 10);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accesslog`
--
ALTER TABLE `accesslog`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`admin_id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `allergentag`
--
ALTER TABLE `allergentag`
  ADD PRIMARY KEY (`allergen_id`),
  ADD UNIQUE KEY `allergen_name` (`allergen_name`);

--
-- Indexes for table `auditlog`
--
ALTER TABLE `auditlog`
  ADD PRIMARY KEY (`audit_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `claimrequest`
--
ALTER TABLE `claimrequest`
  ADD PRIMARY KEY (`claim_id`),
  ADD KEY `listing_id` (`listing_id`),
  ADD KEY `receiver_id` (`receiver_id`);

--
-- Indexes for table `deliveryroutelog`
--
ALTER TABLE `deliveryroutelog`
  ADD PRIMARY KEY (`route_log_id`),
  ADD KEY `assignment_id` (`assignment_id`);

--
-- Indexes for table `donororganization`
--
ALTER TABLE `donororganization`
  ADD PRIMARY KEY (`donor_id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD UNIQUE KEY `trade_license_no` (`trade_license_no`),
  ADD KEY `zone_id` (`zone_id`);

--
-- Indexes for table `feedbackrating`
--
ALTER TABLE `feedbackrating`
  ADD PRIMARY KEY (`feedback_id`),
  ADD UNIQUE KEY `claim_id` (`claim_id`),
  ADD KEY `receiver_id` (`receiver_id`);

--
-- Indexes for table `foodcategory`
--
ALTER TABLE `foodcategory`
  ADD PRIMARY KEY (`category_id`);

--
-- Indexes for table `impactmetric`
--
ALTER TABLE `impactmetric`
  ADD PRIMARY KEY (`metric_id`),
  ADD UNIQUE KEY `donor_id` (`donor_id`);

--
-- Indexes for table `incidentreport`
--
ALTER TABLE `incidentreport`
  ADD PRIMARY KEY (`incident_id`),
  ADD KEY `listing_id` (`listing_id`),
  ADD KEY `reported_by_user` (`reported_by_user`);

--
-- Indexes for table `listingallergenmap`
--
ALTER TABLE `listingallergenmap`
  ADD PRIMARY KEY (`listing_id`,`allergen_id`),
  ADD KEY `allergen_id` (`allergen_id`);

--
-- Indexes for table `locationzone`
--
ALTER TABLE `locationzone`
  ADD PRIMARY KEY (`zone_id`);

--
-- Indexes for table `notificationalert`
--
ALTER TABLE `notificationalert`
  ADD PRIMARY KEY (`alert_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `pickupassignment`
--
ALTER TABLE `pickupassignment`
  ADD PRIMARY KEY (`assignment_id`),
  ADD UNIQUE KEY `claim_id` (`claim_id`),
  ADD KEY `volunteer_id` (`volunteer_id`);

--
-- Indexes for table `receiverorganization`
--
ALTER TABLE `receiverorganization`
  ADD PRIMARY KEY (`receiver_id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD UNIQUE KEY `reg_number` (`reg_number`),
  ADD KEY `zone_id` (`zone_id`);

--
-- Indexes for table `safetyinspection`
--
ALTER TABLE `safetyinspection`
  ADD PRIMARY KEY (`inspection_id`),
  ADD KEY `listing_id` (`listing_id`);

--
-- Indexes for table `surpluslisting`
--
ALTER TABLE `surpluslisting`
  ADD PRIMARY KEY (`listing_id`),
  ADD KEY `donor_id` (`donor_id`),
  ADD KEY `category_id` (`category_id`);

--
-- Indexes for table `useraccount`
--
ALTER TABLE `useraccount`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `volunteer`
--
ALTER TABLE `volunteer`
  ADD PRIMARY KEY (`volunteer_id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD UNIQUE KEY `nid_number` (`nid_number`),
  ADD KEY `zone_id` (`zone_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accesslog`
--
ALTER TABLE `accesslog`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `admin`
--
ALTER TABLE `admin`
  MODIFY `admin_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `allergentag`
--
ALTER TABLE `allergentag`
  MODIFY `allergen_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `auditlog`
--
ALTER TABLE `auditlog`
  MODIFY `audit_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `claimrequest`
--
ALTER TABLE `claimrequest`
  MODIFY `claim_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `deliveryroutelog`
--
ALTER TABLE `deliveryroutelog`
  MODIFY `route_log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `donororganization`
--
ALTER TABLE `donororganization`
  MODIFY `donor_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `feedbackrating`
--
ALTER TABLE `feedbackrating`
  MODIFY `feedback_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `foodcategory`
--
ALTER TABLE `foodcategory`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `impactmetric`
--
ALTER TABLE `impactmetric`
  MODIFY `metric_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `incidentreport`
--
ALTER TABLE `incidentreport`
  MODIFY `incident_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `locationzone`
--
ALTER TABLE `locationzone`
  MODIFY `zone_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `notificationalert`
--
ALTER TABLE `notificationalert`
  MODIFY `alert_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `pickupassignment`
--
ALTER TABLE `pickupassignment`
  MODIFY `assignment_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `receiverorganization`
--
ALTER TABLE `receiverorganization`
  MODIFY `receiver_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `safetyinspection`
--
ALTER TABLE `safetyinspection`
  MODIFY `inspection_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `surpluslisting`
--
ALTER TABLE `surpluslisting`
  MODIFY `listing_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `useraccount`
--
ALTER TABLE `useraccount`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `volunteer`
--
ALTER TABLE `volunteer`
  MODIFY `volunteer_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `accesslog`
--
ALTER TABLE `accesslog`
  ADD CONSTRAINT `accesslog_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `useraccount` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `admin`
--
ALTER TABLE `admin`
  ADD CONSTRAINT `admin_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `useraccount` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `auditlog`
--
ALTER TABLE `auditlog`
  ADD CONSTRAINT `auditlog_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `useraccount` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `claimrequest`
--
ALTER TABLE `claimrequest`
  ADD CONSTRAINT `claimrequest_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `surpluslisting` (`listing_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `claimrequest_ibfk_2` FOREIGN KEY (`receiver_id`) REFERENCES `receiverorganization` (`receiver_id`) ON DELETE CASCADE;

--
-- Constraints for table `deliveryroutelog`
--
ALTER TABLE `deliveryroutelog`
  ADD CONSTRAINT `deliveryroutelog_ibfk_1` FOREIGN KEY (`assignment_id`) REFERENCES `pickupassignment` (`assignment_id`) ON DELETE CASCADE;

--
-- Constraints for table `donororganization`
--
ALTER TABLE `donororganization`
  ADD CONSTRAINT `donororganization_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `useraccount` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `donororganization_ibfk_2` FOREIGN KEY (`zone_id`) REFERENCES `locationzone` (`zone_id`);

--
-- Constraints for table `feedbackrating`
--
ALTER TABLE `feedbackrating`
  ADD CONSTRAINT `feedbackrating_ibfk_1` FOREIGN KEY (`claim_id`) REFERENCES `claimrequest` (`claim_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `feedbackrating_ibfk_2` FOREIGN KEY (`receiver_id`) REFERENCES `receiverorganization` (`receiver_id`);

--
-- Constraints for table `impactmetric`
--
ALTER TABLE `impactmetric`
  ADD CONSTRAINT `impactmetric_ibfk_1` FOREIGN KEY (`donor_id`) REFERENCES `donororganization` (`donor_id`) ON DELETE CASCADE;

--
-- Constraints for table `incidentreport`
--
ALTER TABLE `incidentreport`
  ADD CONSTRAINT `incidentreport_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `surpluslisting` (`listing_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `incidentreport_ibfk_2` FOREIGN KEY (`reported_by_user`) REFERENCES `useraccount` (`user_id`);

--
-- Constraints for table `listingallergenmap`
--
ALTER TABLE `listingallergenmap`
  ADD CONSTRAINT `listingallergenmap_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `surpluslisting` (`listing_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `listingallergenmap_ibfk_2` FOREIGN KEY (`allergen_id`) REFERENCES `allergentag` (`allergen_id`) ON DELETE CASCADE;

--
-- Constraints for table `notificationalert`
--
ALTER TABLE `notificationalert`
  ADD CONSTRAINT `notificationalert_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `useraccount` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `pickupassignment`
--
ALTER TABLE `pickupassignment`
  ADD CONSTRAINT `pickupassignment_ibfk_1` FOREIGN KEY (`claim_id`) REFERENCES `claimrequest` (`claim_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `pickupassignment_ibfk_2` FOREIGN KEY (`volunteer_id`) REFERENCES `volunteer` (`volunteer_id`);

--
-- Constraints for table `receiverorganization`
--
ALTER TABLE `receiverorganization`
  ADD CONSTRAINT `receiverorganization_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `useraccount` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `receiverorganization_ibfk_2` FOREIGN KEY (`zone_id`) REFERENCES `locationzone` (`zone_id`);

--
-- Constraints for table `safetyinspection`
--
ALTER TABLE `safetyinspection`
  ADD CONSTRAINT `safetyinspection_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `surpluslisting` (`listing_id`) ON DELETE CASCADE;

--
-- Constraints for table `surpluslisting`
--
ALTER TABLE `surpluslisting`
  ADD CONSTRAINT `surpluslisting_ibfk_1` FOREIGN KEY (`donor_id`) REFERENCES `donororganization` (`donor_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `surpluslisting_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `foodcategory` (`category_id`);

--
-- Constraints for table `volunteer`
--
ALTER TABLE `volunteer`
  ADD CONSTRAINT `volunteer_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `useraccount` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `volunteer_ibfk_2` FOREIGN KEY (`zone_id`) REFERENCES `locationzone` (`zone_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
