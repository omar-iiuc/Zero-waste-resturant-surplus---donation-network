<?php
include 'db_connect.php';
$message = "";

// 1. নতুন Location Zone অ্যাড করার লজিক
if (isset($_POST['add_zone'])) {
    $zone_name = trim($_POST['zone_name']);
    $city = trim($_POST['city']);
    $postal_code = trim($_POST['postal_code']);

    $safe_zone = $conn->real_escape_string($zone_name);
    $safe_city = $conn->real_escape_string($city !== '' ? $city : 'Chattogram');
    $safe_postal = $conn->real_escape_string($postal_code !== '' ? $postal_code : '4000');

    // চট্টগ্রামের ডিফল্ট কো-অর্ডিনেটসহ সেভ হবে
    $sql = "INSERT INTO LocationZone (zone_name, city, postal_code, latitude, longitude)
            VALUES ('$safe_zone', '$safe_city', '$safe_postal', 22.35690000, 91.78320000)";

    try {
        $conn->query($sql);
        $message = "<div class='alert alert-success'>নতুন লোকেশন জোন <strong>" . htmlspecialchars($zone_name) . "</strong> সফলভাবে যুক্ত হয়েছে!</div>";
    } catch (Exception $e) {
        $message = "<div class='alert alert-danger'>জোন অ্যাড করা যায়নি: " . htmlspecialchars($e->getMessage()) . "</div>";
    }
}

// 2. নতুন রেস্তোরাঁ (Donor) অ্যাড করার লজিক (Transaction: 3 Tables)
if (isset($_POST['add_restaurant'])) {
    $org_name = trim($_POST['org_name']);
    $zone_id = (int)$_POST['zone_id'];
    $phone = trim($_POST['phone']);
    $address = trim($_POST['address']);

    $safe_org = $conn->real_escape_string($org_name);
    $safe_phone = $conn->real_escape_string($phone);
    $safe_address = $conn->real_escape_string($address);

    $slug = trim(strtolower(preg_replace('/[^a-zA-Z0-9]+/', '', $org_name)), '');
    if ($slug === '') { $slug = 'donor'; }
    $rand = rand(100, 999);
    $username = $conn->real_escape_string(substr($slug, 0, 20) . '_' . $rand);
    $email = $conn->real_escape_string($username . '@zerowaste.org');
    $license = $conn->real_escape_string('TL-CTG-2026-' . rand(200, 9999));

    $conn->begin_transaction();
    try {
        $conn->query("INSERT INTO UserAccount (username, email, password_hash, phone, user_role, account_status)
                      VALUES ('$username', '$email', 'hash_donor_$rand', '$safe_phone', 'Donor', 'Active')");
        $new_user_id = $conn->insert_id;

        $conn->query("INSERT INTO DonorOrganization (user_id, zone_id, org_name, org_type, trade_license_no, address, hygiene_rating, is_verified)
                      VALUES ($new_user_id, $zone_id, '$safe_org', 'Restaurant', '$license', '$safe_address', 4.80, TRUE)");
        $new_donor_id = $conn->insert_id;

        $conn->query("INSERT INTO ImpactMetric (donor_id, total_meals_donated, total_food_saved_kg, co2_offset_kg)
                      VALUES ($new_donor_id, 0, 0.00, 0.00)");

        $conn->commit();
        $message = "<div class='alert alert-success'>নতুন রেস্তোরাঁ <strong>" . htmlspecialchars($org_name) . "</strong> যুক্ত হয়েছে! এখন উপরের ড্রপডাউন থেকে এটি সিলেক্ট করে খাবার পোস্ট করতে পারবে।</div>";
    } catch (Exception $e) {
        $conn->rollback();
        $message = "<div class='alert alert-danger'>রেস্তোরাঁ অ্যাড করা যায়নি: " . htmlspecialchars($e->getMessage()) . "</div>";
    }
}

// 3. নতুন এতিমখানা / শেল্টার (Receiver) অ্যাড করার লজিক (Transaction: 2 Tables)
if (isset($_POST['add_receiver'])) {
    $org_name = trim($_POST['receiver_name']);
    $zone_id = (int)$_POST['zone_id'];
    $headcount = (int)$_POST['daily_headcount'];
    $priority = $_POST['priority_level'];
    if (!in_array($priority, ['High', 'Medium', 'Low'])) { $priority = 'Medium'; }
    $phone = trim($_POST['phone']);
    $address = trim($_POST['address']);

    $safe_org = $conn->real_escape_string($org_name);
    $safe_phone = $conn->real_escape_string($phone);
    $safe_address = $conn->real_escape_string($address);

    $slug = trim(strtolower(preg_replace('/[^a-zA-Z0-9]+/', '', $org_name)), '');
    if ($slug === '') { $slug = 'receiver'; }
    $rand = rand(100, 999);
    $username = $conn->real_escape_string(substr($slug, 0, 20) . '_' . $rand);
    $email = $conn->real_escape_string($username . '@zerowaste.org');
    $reg_no = $conn->real_escape_string('DSS-CTG-' . rand(600, 9999));

    $conn->begin_transaction();
    try {
        $conn->query("INSERT INTO UserAccount (username, email, password_hash, phone, user_role, account_status)
                      VALUES ('$username', '$email', 'hash_recv_$rand', '$safe_phone', 'Receiver', 'Active')");
        $new_user_id = $conn->insert_id;

        $conn->query("INSERT INTO ReceiverOrganization (user_id, zone_id, org_name, reg_number, daily_headcount, address, priority_level)
                      VALUES ($new_user_id, $zone_id, '$safe_org', '$reg_no', $headcount, '$safe_address', '$priority')");

        $conn->commit();
        $message = "<div class='alert alert-success'>নতুন এতিমখানা / শেল্টার <strong>" . htmlspecialchars($org_name) . "</strong> যুক্ত হয়েছে! এখন খাবার Claim করার সময় এটি সিলেক্ট করতে পারবে।</div>";
    } catch (Exception $e) {
        $conn->rollback();
        $message = "<div class='alert alert-danger'>এতিমখানা অ্যাড করা যায়নি: " . htmlspecialchars($e->getMessage()) . "</div>";
    }
}

// 4. নতুন খাবার পোস্ট করার লজিক (Donor Action)
if (isset($_POST['add_food'])) {
    $donor_id = (int)$_POST['donor_id'];
    $category_id = (int)$_POST['category_id'];
    $food_title = $conn->real_escape_string($_POST['food_title']);
    $servings = (int)$_POST['quantity_servings'];
    $weight = (float)$_POST['estimated_weight_kg'];

    $sql = "INSERT INTO SurplusListing (donor_id, category_id, food_title, quantity_servings, estimated_weight_kg, cooked_time, expiry_time, pickup_window_end, listing_status)
            VALUES ($donor_id, $category_id, '$food_title', $servings, $weight, NOW(), DATE_ADD(NOW(), INTERVAL 4 HOUR), DATE_ADD(NOW(), INTERVAL 2 HOUR), 'Available')";
    
    if ($conn->query($sql)) {
        $message = "<div class='alert alert-success'>নতুন সারপ্লাস খাবার সফলভাবে পোস্ট হয়েছে!</div>";
    } else {
        $message = "<div class='alert alert-danger'>Error: " . $conn->error . "</div>";
    }
}

// 5. খাবার ক্লেইম করার লজিক (Receiver Action -> Fires Trigger 1)
if (isset($_POST['claim_food'])) {
    $listing_id = (int)$_POST['listing_id'];
    $receiver_id = (int)$_POST['receiver_id'];
    $servings = (int)$_POST['requested_servings'];
    $otp = "OTP-" . rand(1000, 9999);

    $sql = "INSERT INTO ClaimRequest (listing_id, receiver_id, requested_servings, claim_status, verification_otp)
            VALUES ($listing_id, $receiver_id, $servings, 'Approved', '$otp')";

    if ($conn->query($sql)) {
        $message = "<div class='alert alert-info'>খাবার ক্লেইম সম্পন্ন! <strong>Trigger 1</strong> অটোমেটিক স্টক লক করে AuditLog আপডেট করেছে (OTP: $otp)।</div>";
    } else {
        $message = "<div class='alert alert-danger'>Error: " . $conn->error . "</div>";
    }
}

// 6. ডেলিভারি সম্পন্ন করার লজিক (Volunteer Action -> Fires Trigger 2)
if (isset($_POST['complete_delivery'])) {
    $listing_id = (int)$_POST['listing_id'];
    $volunteer_id = 2; // Tanvir Ahmed

    $res = $conn->query("SELECT claim_id FROM ClaimRequest WHERE listing_id = $listing_id LIMIT 1");
    if ($row = $res->fetch_assoc()) {
        $claim_id = $row['claim_id'];
        $conn->query("INSERT INTO PickupAssignment (claim_id, volunteer_id, picked_up_at, dispatch_status) 
                      VALUES ($claim_id, $volunteer_id, NOW(), 'Picked_Up')
                      ON DUPLICATE KEY UPDATE dispatch_status='Picked_Up'");
        
        $conn->query("UPDATE PickupAssignment SET dispatch_status = 'Delivered', delivered_at = NOW() WHERE claim_id = $claim_id");
        $message = "<div class='alert alert-success'>ডেলিভারি সম্পন্ন! <strong>Trigger 2</strong> অটোমেটিক ৪টি টেবিল ও CSR ImpactMetric আপডেট করেছে।</div>";
    }
}

// ড্রপডাউনের জন্য Zones এবং Receivers একবার লোড করে রাখা
$zones_list = [];
$z_res = $conn->query("SELECT zone_id, zone_name FROM LocationZone ORDER BY zone_id DESC");
while ($z = $z_res->fetch_assoc()) { $zones_list[] = $z; }

$receivers_list = [];
$r_res = $conn->query("SELECT receiver_id, org_name FROM ReceiverOrganization ORDER BY receiver_id DESC");
while ($r = $r_res->fetch_assoc()) { $receivers_list[] = $r; }

// ড্যাশবোর্ডের সামারি ডেটা (Aggregate Queries)
$impact = $conn->query("SELECT SUM(total_meals_donated) AS meals, SUM(total_food_saved_kg) AS kg, SUM(co2_offset_kg) AS co2 FROM ImpactMetric")->fetch_assoc();
$active_count = $conn->query("SELECT COUNT(*) AS cnt FROM SurplusListing WHERE listing_status = 'Available'")->fetch_assoc()['cnt'];
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zero-Waste Surplus & Donation Network</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f4f7f6; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        .navbar { background: linear-gradient(135deg, #1b4332, #2d6a4f); }
        .stat-card { border: none; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.06); }
        .table-card { border: none; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
        .nav-pills .nav-link { font-size: 0.85rem; padding: 6px 10px; font-weight: 600; }
    </style>
</head>
<body>

<nav class="navbar navbar-dark py-3 mb-4">
    <div class="container">
        <span class="navbar-brand fw-bold fs-4">🌱 Zero-Waste Restaurant Surplus & Donation Network</span>
        <span class="badge bg-light text-dark">CSE-2424 | 20-Table Relational DB</span>
    </div>
</nav>

<div class="container pb-5">
    <?= $message ?>

    <!-- Top KPI Cards -->
    <div class="row g-3 mb-4">
        <div class="col-md-3">
            <div class="card stat-card p-3 bg-white border-start border-success border-4">
                <small class="text-muted fw-bold">TOTAL MEALS DONATED</small>
                <h2 class="fw-bold text-success mb-0"><?= number_format($impact['meals'] ?? 0) ?></h2>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card stat-card p-3 bg-white border-start border-primary border-4">
                <small class="text-muted fw-bold">FOOD SAVED (KG)</small>
                <h2 class="fw-bold text-primary mb-0"><?= number_format($impact['kg'] ?? 0, 2) ?> kg</h2>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card stat-card p-3 bg-white border-start border-warning border-4">
                <small class="text-muted fw-bold">CO2 EMISSION OFFSET</small>
                <h2 class="fw-bold text-warning mb-0"><?= number_format($impact['co2'] ?? 0, 2) ?> kg</h2>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card stat-card p-3 bg-white border-start border-danger border-4">
                <small class="text-muted fw-bold">AVAILABLE LISTINGS</small>
                <h2 class="fw-bold text-danger mb-0"><?= $active_count ?></h2>
            </div>
        </div>
    </div>

    <div class="row g-4">
        <!-- Left Column: Post Food + 3-in-1 Registration Panel -->
        <div class="col-lg-4">
            <!-- Form 1: Post Surplus Food -->
            <div class="card table-card p-4 bg-white mb-4">
                <h5 class="fw-bold mb-3 text-success">+ Post Surplus Food (Donor)</h5>
                <form method="POST">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Restaurant / Donor</label>
                        <select name="donor_id" class="form-select" required>
                            <?php
                            $donors = $conn->query("SELECT donor_id, org_name FROM DonorOrganization ORDER BY donor_id DESC");
                            while ($d = $donors->fetch_assoc()) {
                                echo "<option value='{$d['donor_id']}'>" . htmlspecialchars($d['org_name']) . "</option>";
                            }
                            ?>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Food Category</label>
                        <select name="category_id" class="form-select" required>
                            <?php
                            $cats = $conn->query("SELECT category_id, category_name FROM FoodCategory");
                            while ($c = $cats->fetch_assoc()) {
                                echo "<option value='{$c['category_id']}'>" . htmlspecialchars($c['category_name']) . "</option>";
                            }
                            ?>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Food Title</label>
                        <input type="text" name="food_title" class="form-control" placeholder="e.g., Chicken Biryani Packets" required>
                    </div>
                    <div class="row mb-3">
                        <div class="col">
                            <label class="form-label fw-semibold">Servings</label>
                            <input type="number" name="quantity_servings" class="form-control" value="25" min="1" required>
                        </div>
                        <div class="col">
                            <label class="form-label fw-semibold">Weight (kg)</label>
                            <input type="number" step="0.1" name="estimated_weight_kg" class="form-control" value="12.5" min="0.5" required>
                        </div>
                    </div>
                    <button type="submit" name="add_food" class="btn btn-success w-100 fw-bold">Publish Surplus Listing</button>
                </form>
            </div>

            <!-- Form 2: Tabbed Quick Registration (Restaurant / Orphanage / Zone) -->
            <div class="card table-card p-4 bg-white border-top border-primary border-4">
                <h6 class="fw-bold text-primary mb-3">⚙️ Add New Entities to Network</h6>

                <ul class="nav nav-pills nav-fill mb-3 bg-light p-1 rounded" id="regTabs" role="tablist">
                    <li class="nav-item" role="presentation">
                        <button class="nav-link active" data-bs-toggle="pill" data-bs-target="#tab-restaurant" type="button">+ Restaurant</button>
                    </li>
                    <li class="nav-item" role="presentation">
                        <button class="nav-link" data-bs-toggle="pill" data-bs-target="#tab-orphanage" type="button">+ Orphanage</button>
                    </li>
                    <li class="nav-item" role="presentation">
                        <button class="nav-link" data-bs-toggle="pill" data-bs-target="#tab-zone" type="button">+ Zone</button>
                    </li>
                </ul>

                <div class="tab-content">
                    <!-- Tab 1: Add Restaurant -->
                    <div class="tab-pane fade show active" id="tab-restaurant">
                        <form method="POST">
                            <div class="mb-2">
                                <label class="form-label small fw-semibold">Restaurant Name</label>
                                <input type="text" name="org_name" class="form-control form-control-sm" placeholder="e.g., Sultan's Dine - Nasirabad" required>
                            </div>
                            <div class="mb-2">
                                <label class="form-label small fw-semibold">Location Zone</label>
                                <select name="zone_id" class="form-select form-select-sm" required>
                                    <?php foreach ($zones_list as $z): ?>
                                        <option value="<?= $z['zone_id'] ?>"><?= htmlspecialchars($z['zone_name']) ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            <div class="mb-2">
                                <label class="form-label small fw-semibold">Contact Phone</label>
                                <input type="text" name="phone" class="form-control form-control-sm" placeholder="01812345678" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label small fw-semibold">Full Address</label>
                                <input type="text" name="address" class="form-control form-control-sm" placeholder="CDA Avenue, Chattogram" required>
                            </div>
                            <button type="submit" name="add_restaurant" class="btn btn-primary btn-sm w-100 fw-bold">Register Restaurant</button>
                        </form>
                    </div>

                    <!-- Tab 2: Add Orphanage / Receiver -->
                    <div class="tab-pane fade" id="tab-orphanage">
                        <form method="POST">
                            <div class="mb-2">
                                <label class="form-label small fw-semibold">Orphanage / Shelter Name</label>
                                <input type="text" name="receiver_name" class="form-control form-control-sm" placeholder="e.g., Baitul Aman Shishu Sadan" required>
                            </div>
                            <div class="mb-2">
                                <label class="form-label small fw-semibold">Location Zone</label>
                                <select name="zone_id" class="form-select form-select-sm" required>
                                    <?php foreach ($zones_list as $z): ?>
                                        <option value="<?= $z['zone_id'] ?>"><?= htmlspecialchars($z['zone_name']) ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            <div class="row mb-2">
                                <div class="col">
                                    <label class="form-label small fw-semibold">Headcount</label>
                                    <input type="number" name="daily_headcount" class="form-control form-control-sm" value="60" min="5" required>
                                </div>
                                <div class="col">
                                    <label class="form-label small fw-semibold">Priority</label>
                                    <select name="priority_level" class="form-select form-select-sm">
                                        <option value="High">High</option>
                                        <option value="Medium" selected>Medium</option>
                                        <option value="Low">Low</option>
                                    </select>
                                </div>
                            </div>
                            <div class="mb-2">
                                <label class="form-label small fw-semibold">Contact Phone</label>
                                <input type="text" name="phone" class="form-control form-control-sm" placeholder="01712345678" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label small fw-semibold">Full Address</label>
                                <input type="text" name="address" class="form-control form-control-sm" placeholder="Chawkbazar, Chattogram" required>
                            </div>
                            <button type="submit" name="add_receiver" class="btn btn-info text-white btn-sm w-100 fw-bold">Register Orphanage</button>
                        </form>
                    </div>

                    <!-- Tab 3: Add Location Zone -->
                    <div class="tab-pane fade" id="tab-zone">
                        <form method="POST">
                            <div class="mb-2">
                                <label class="form-label small fw-semibold">Zone / Area Name</label>
                                <input type="text" name="zone_name" class="form-control form-control-sm" placeholder="e.g., Nasirabad / 2 No. Gate" required>
                            </div>
                            <div class="mb-2">
                                <label class="form-label small fw-semibold">City</label>
                                <input type="text" name="city" class="form-control form-control-sm" value="Chattogram" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label small fw-semibold">Postal Code</label>
                                <input type="text" name="postal_code" class="form-control form-control-sm" placeholder="e.g., 4209" required>
                            </div>
                            <button type="submit" name="add_zone" class="btn btn-dark btn-sm w-100 fw-bold">Add Location Zone</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <!-- Right Column: Live Surplus Feed & Actions -->
        <div class="col-lg-8">
            <div class="card table-card p-4 bg-white mb-4">
                <h5 class="fw-bold mb-3">Live Surplus Food Feed (Multi-Table JOIN)</h5>
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Food Item</th>
                                <th>Donor & Zone</th>
                                <th>Qty / Weight</th>
                                <th>Status</th>
                                <th style="min-width: 170px;">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                            $query = "SELECT s.listing_id, s.food_title, s.quantity_servings, s.estimated_weight_kg, s.listing_status, 
                                             d.org_name, z.zone_name, c.category_name
                                      FROM SurplusListing s
                                      JOIN DonorOrganization d ON s.donor_id = d.donor_id
                                      JOIN LocationZone z ON d.zone_id = z.zone_id
                                      JOIN FoodCategory c ON s.category_id = c.category_id
                                      ORDER BY s.listing_id DESC";
                            $listings = $conn->query($query);
                            while ($row = $listings->fetch_assoc()):
                                $badge = match($row['listing_status']) {
                                    'Available' => 'bg-success',
                                    'Claimed' => 'bg-warning text-dark',
                                    'Delivered' => 'bg-primary',
                                    default => 'bg-secondary'
                                };
                            ?>
                            <tr>
                                <td>
                                    <strong><?= htmlspecialchars($row['food_title']) ?></strong><br>
                                    <small class="text-muted"><?= htmlspecialchars($row['category_name']) ?></small>
                                </td>
                                <td>
                                    <?= htmlspecialchars($row['org_name']) ?><br>
                                    <small class="text-muted">📍 <?= htmlspecialchars($row['zone_name']) ?></small>
                                </td>
                                <td><?= $row['quantity_servings'] ?> meals<br><small class="text-muted">(<?= $row['estimated_weight_kg'] ?> kg)</small></td>
                                <td><span class="badge <?= $badge ?>"><?= $row['listing_status'] ?></span></td>
                                <td>
                                    <?php if ($row['listing_status'] == 'Available'): ?>
                                        <form method="POST">
                                            <input type="hidden" name="listing_id" value="<?= $row['listing_id'] ?>">
                                            <input type="hidden" name="requested_servings" value="<?= $row['quantity_servings'] ?>">
                                            <select name="receiver_id" class="form-select form-select-sm mb-1" required>
                                                <?php foreach ($receivers_list as $r): ?>
                                                    <option value="<?= $r['receiver_id'] ?>"><?= htmlspecialchars($r['org_name']) ?></option>
                                                <?php endforeach; ?>
                                            </select>
                                            <button type="submit" name="claim_food" class="btn btn-sm btn-outline-success w-100 fw-bold">Claim Food</button>
                                        </form>
                                    <?php elseif ($row['listing_status'] == 'Claimed'): ?>
                                        <form method="POST" class="d-inline">
                                            <input type="hidden" name="listing_id" value="<?= $row['listing_id'] ?>">
                                            <button type="submit" name="complete_delivery" class="btn btn-sm btn-primary w-100 fw-bold">Deliver (Volunteer)</button>
                                        </form>
                                    <?php else: ?>
                                        <span class="text-muted small">✔️ Completed</span>
                                    <?php endif; ?>
                                </td>
                            </tr>
                            <?php endwhile; ?>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Live Trigger Audit Log -->
            <div class="card table-card p-4 bg-white">
                <h6 class="fw-bold text-secondary mb-3">⚡ Automated Database Trigger Logs (AuditLog Table)</h6>
                <table class="table table-sm table-bordered mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Audit ID</th>
                            <th>Action</th>
                            <th>Details</th>
                            <th>Timestamp</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php
                        $logs = $conn->query("SELECT * FROM AuditLog ORDER BY audit_id DESC LIMIT 5");
                        while ($l = $logs->fetch_assoc()):
                        ?>
                        <tr>
                            <td>#<?= $l['audit_id'] ?></td>
                            <td><span class="badge bg-dark"><?= htmlspecialchars($l['action_type']) ?></span></td>
                            <td><?= htmlspecialchars($l['action_details']) ?></td>
                            <td class="text-muted small"><?= $l['action_timestamp'] ?></td>
                        </tr>
                        <?php endwhile; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>