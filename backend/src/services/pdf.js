const PDFDocument = require('pdfkit');

class PdfService {
  generateSessionInvoice(stream, sessionData) {
    const doc = new PDFDocument({ margin: 50 });
    doc.pipe(stream);

    // Header
    doc.fillColor('#0F5132').fontSize(24).text('Hijama Center Pro', 50, 50);
    doc.fillColor('#333333').fontSize(10).text('Premium Treatment Center & Medical Supplies', 50, 80);
    
    doc.fontSize(10).text(`Invoice ID: ${sessionData.id}`, 350, 50);
    doc.text(`Date: ${new Date(sessionData.date).toLocaleString()}`, 350, 65);
    doc.text(`Operator: ${sessionData.employee_name || 'Clinic Staff'}`, 350, 80);

    // Line separator
    doc.moveTo(50, 105).lineTo(550, 105).stroke('#CCCCCC');

    // Customer Info
    doc.fontSize(12).fillColor('#0F5132').text('Customer Details', 50, 120);
    doc.fontSize(10).fillColor('#333333');
    doc.text(`Name: ${sessionData.customer_name}`, 50, 140);
    doc.text(`Phone: ${sessionData.customer_phone || 'N/A'}`, 50, 155);

    // Session Info
    doc.fontSize(12).fillColor('#0F5132').text('Treatment Details', 50, 185);
    doc.fontSize(10).fillColor('#333333');
    doc.text(`Session Type: ${sessionData.session_type.replace('_', ' ')}`, 50, 205);
    doc.text(`Cups Used: ${sessionData.cups_used || 0}`, 50, 220);
    doc.text(`Notes: ${sessionData.notes || 'None'}`, 50, 235);

    // Line separator
    doc.moveTo(50, 260).lineTo(550, 260).stroke('#CCCCCC');

    // Price details table-style
    doc.fontSize(12).fillColor('#0F5132').text('Financial Statement', 50, 280);
    doc.fontSize(10).fillColor('#333333');
    
    doc.text('Session Cost:', 50, 305);
    doc.text(`${parseFloat(sessionData.total_cost).toFixed(2)} DA`, 150, 305);

    doc.text('Amount Paid:', 50, 320);
    doc.text(`${parseFloat(sessionData.price_paid).toFixed(2)} DA`, 150, 320);

    doc.text('Remaining Debt:', 50, 335);
    doc.fillColor(sessionData.debt_amount > 0 ? '#C0392B' : '#333333');
    doc.text(`${parseFloat(sessionData.debt_amount).toFixed(2)} DA`, 150, 335);

    // Consumables used details
    if (sessionData.materials && sessionData.materials.length > 0) {
      doc.moveTo(50, 360).lineTo(550, 360).stroke('#CCCCCC');
      doc.fontSize(12).fillColor('#0F5132').text('Materials Used', 50, 375);
      doc.fontSize(10).fillColor('#333333');
      
      let y = 395;
      sessionData.materials.forEach(mat => {
        doc.text(`${mat.item_name}`, 50, y);
        doc.text(`Qty: ${mat.quantity_used}`, 250, y);
        y += 15;
      });
    }

    // Footer
    doc.fontSize(8).fillColor('#7F8C8D').text('Thank you for trusting Hijama Center Pro. Have a healthy day!', 50, 700, { align: 'center' });

    doc.end();
  }

  generateDailyReport(stream, stats, dateStr) {
    const doc = new PDFDocument({ margin: 50 });
    doc.pipe(stream);

    // Header
    doc.fillColor('#0F5132').fontSize(24).text('Hijama Center Pro', 50, 50);
    doc.fillColor('#333333').fontSize(12).text(`Daily Financial & Operational Report - ${dateStr}`, 50, 80);

    // Line separator
    doc.moveTo(50, 105).lineTo(550, 105).stroke('#CCCCCC');

    // Stats Section
    doc.fontSize(14).fillColor('#0F5132').text('Key Highlights Today', 50, 120);
    doc.fontSize(10).fillColor('#333333');
    
    doc.text(`Customers Served Today:`, 50, 150);
    doc.text(`${stats.customersToday}`, 250, 150);

    doc.text(`Revenue Logged Today:`, 50, 170);
    doc.text(`${stats.revenueToday.toFixed(2)} DA`, 250, 170);

    doc.text(`Operating Expenses Today:`, 50, 190);
    doc.text(`${stats.expensesToday.toFixed(2)} DA`, 250, 190);

    doc.text(`Net Clinic Profit Today:`, 50, 210);
    doc.fillColor(stats.profitToday >= 0 ? '#0F5132' : '#C0392B');
    doc.text(`${stats.profitToday.toFixed(2)} DA`, 250, 210);

    // Line separator
    doc.moveTo(50, 240).lineTo(550, 240).stroke('#CCCCCC');

    // General Information
    doc.fontSize(12).fillColor('#333333').text('Inventory & Future Bookings Status', 50, 260);
    doc.fontSize(10);
    doc.text(`Current Assets Value (Inventory Stock): ${stats.inventoryValue.toFixed(2)} DA`, 50, 285);
    doc.text(`Pending Upcoming Appointments: ${stats.upcomingAppointments}`, 50, 305);
    doc.text(`Categories Below Minimum Thresholds: ${stats.lowStockAlerts}`, 50, 325);

    // Footer
    doc.fontSize(8).fillColor('#7F8C8D').text('Hijama Center Pro Automated PDF System', 50, 700, { align: 'center' });

    doc.end();
  }

  generateInventoryReport(stream, items) {
    const doc = new PDFDocument({ margin: 50 });
    doc.pipe(stream);

    // Header
    doc.fillColor('#0F5132').fontSize(24).text('Hijama Center Pro', 50, 50);
    doc.fillColor('#333333').fontSize(12).text('Clinic Inventory Stock Checklist', 50, 80);

    doc.moveTo(50, 105).lineTo(550, 105).stroke('#CCCCCC');

    // Table Headers
    doc.fontSize(10).fillColor('#0F5132');
    doc.text('Item Name', 50, 120);
    doc.text('Current Qty', 250, 120);
    doc.text('Min Limit', 350, 120);
    doc.text('Supplier', 430, 120);

    doc.moveTo(50, 135).lineTo(550, 135).stroke('#CCCCCC');

    doc.fillColor('#333333');
    let y = 145;
    
    items.forEach(item => {
      // If low stock, color the line differently
      if (item.quantity <= item.min_threshold) {
        doc.fillColor('#C0392B');
      } else {
        doc.fillColor('#333333');
      }

      doc.text(item.name, 50, y);
      doc.text(`${item.quantity}`, 250, y);
      doc.text(`${item.min_threshold}`, 350, y);
      doc.text(item.supplier || 'Unknown', 430, y);

      y += 20;

      // Page break check
      if (y > 700) {
        doc.addPage();
        y = 50;
      }
    });

    doc.end();
  }
}

module.exports = new PdfService();
