use hospital;

--1) Total number of patients per branch

SELECT 
    b.Name AS BranchName,
    COUNT(DISTINCT a.PatientID) AS PatientCount
FROM Appointment a
JOIN Branch b ON b.BranchID = a.BranchID
GROUP BY b.Name
ORDER BY PatientCount DESC;


--2) Number of appointments per doctor per month

SELECT 
    (s.FirstName + ' ' + s.LastName) AS DoctorName,
    YEAR(a.AppointmentDateTime) AS Year,
    MONTH(a.AppointmentDateTime) AS Month,
    COUNT(a.AppointmentID) AS AppointmentCount
FROM Appointment a
JOIN Staff s ON s.StaffID = a.DoctorID
GROUP BY 
    s.FirstName, s.LastName,
    YEAR(a.AppointmentDateTime),
    MONTH(a.AppointmentDateTime)
ORDER BY Year, Month, AppointmentCount DESC;


--3) Top 5 doctors by completed appointments

SELECT TOP 5
    (s.FirstName + ' ' + s.LastName) AS DoctorName,
    COUNT(a.AppointmentID) AS CompletedAppointments
FROM Appointment a
JOIN Staff s ON s.StaffID = a.DoctorID
WHERE a.Status = 'Completed'
GROUP BY s.FirstName, s.LastName
ORDER BY CompletedAppointments DESC;


--4) Bed occupancy rate per branch for a given day

DECLARE @Date DATE = '2025-01-10';

SELECT 
    b.Name AS BranchName,
    COUNT(ba.AssignmentID) * 1.0 / COUNT(bd.BedID) AS OccupancyRate
FROM Bed bd
JOIN Room r 
    ON r.RoomID = bd.RoomID
JOIN Branch b 
    ON b.BranchID = r.BranchID
LEFT JOIN BedAssignment ba 
    ON ba.BedID = bd.BedID
    AND @Date BETWEEN ba.FromDate AND ISNULL(ba.ToDate, @Date)
GROUP BY 
    b.Name;



--5) Total revenue per branch per month

SELECT 
    br.Name AS BranchName,
    YEAR(i.InvoiceDate) AS Year,
    MONTH(i.InvoiceDate) AS Month,
    SUM(il.LineTotal) AS TotalRevenue
FROM Invoice i
JOIN Branch br ON br.BranchID = i.BranchID
JOIN InvoiceLine il ON il.InvoiceID = i.InvoiceID
GROUP BY 
    br.Name,
    YEAR(i.InvoiceDate),
    MONTH(i.InvoiceDate)
ORDER BY TotalRevenue DESC;



--6) Total revenue per department per month

SELECT 
    d.Name AS DepartmentName,
    YEAR(i.InvoiceDate) AS Year,
    MONTH(i.InvoiceDate) AS Month,
    SUM(il.LineTotal) AS TotalRevenue
FROM Invoice i
JOIN Admission a 
    ON a.AdmissionID = i.AdmissionID
JOIN Department d 
    ON d.DepartmentID = a.DepartmentID
JOIN InvoiceLine il 
    ON il.InvoiceID = i.InvoiceID
GROUP BY 
    d.Name,
    YEAR(i.InvoiceDate),
    MONTH(i.InvoiceDate)
ORDER BY TotalRevenue DESC;


--7) Average length of stay per department

SELECT 
    d.Name AS DepartmentName,
    AVG(DATEDIFF(DAY, a.AdmissionDate, a.DischargeDate)) AS AvgStayDays
FROM Admission a
JOIN Department d ON d.DepartmentID = a.DepartmentID
WHERE a.DischargeDate IS NOT NULL
GROUP BY d.Name
ORDER BY AvgStayDays DESC;


-- 8) Revenue: Insurance vs Patient

SELECT 
    SUM(CASE WHEN Method = 'Insurance' THEN Amount ELSE 0 END) AS InsuranceRevenue,
    SUM(CASE WHEN Method = 'Cash' THEN Amount ELSE 0 END) AS PatientRevenue,
    (SUM(CASE WHEN Method = 'Insurance' THEN Amount ELSE 0 END) * 100.0 /
     SUM(Amount)) AS InsurancePercent,
    (SUM(CASE WHEN Method = 'Cash' THEN Amount ELSE 0 END) * 100.0 /
     SUM(Amount)) AS PatientPercent
FROM Payment;

-- 9) Patients with unpaid or partially paid invoices

SELECT 
    p.PatientID,
    p.FullName AS PatientName,
    i.InvoiceID,
    SUM(il.LineTotal) AS TotalAmount,
    ISNULL(SUM(pay.Amount), 0) AS PaidAmount,
    (SUM(il.LineTotal) - ISNULL(SUM(pay.Amount), 0)) AS RemainingBalance
FROM Invoice i
JOIN Patient p 
    ON p.PatientID = i.PatientID
JOIN InvoiceLine il 
    ON il.InvoiceID = i.InvoiceID
LEFT JOIN Payment pay 
    ON pay.InvoiceID = i.InvoiceID
GROUP BY 
    p.PatientID, p.FullName,
    i.InvoiceID
HAVING 
    (SUM(il.LineTotal) - ISNULL(SUM(pay.Amount), 0)) > 0;

--10) New patients registered per month

SELECT 
    YEAR(RegistrationDate) AS Year,
    MONTH(RegistrationDate) AS Month,
    COUNT(PatientID) AS NewPatients
FROM Patient
GROUP BY 
    YEAR(RegistrationDate),
    MONTH(RegistrationDate)
ORDER BY Year, Month;
