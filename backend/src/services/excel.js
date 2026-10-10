const ExcelJS = require('exceljs');

class ExcelService {
  async generateMonthlyFinancialExcel(stream, sessions, expenses, purchases) {
    const workbook = new ExcelJS.Workbook();
    
    // Worksheet 1: Income / Treatments
    const sessionsSheet = workbook.addWorksheet('Treatments (Income)');
    sessionsSheet.columns = [
      { header: 'Session Date', key: 'date', width: 25 },
      { header: 'Customer Name', key: 'customer', width: 25 },
      { header: 'Treatment Type', key: 'type', width: 18 },
      { header: 'Paid Amount', key: 'pricePaid', width: 15 },
      { header: 'Total Price', key: 'totalCost', width: 15 },
      { header: 'Outstanding Debt', key: 'debt', width: 15 },
      { header: 'Cups Used', key: 'cups', width: 12 }
    ];

    sessionsSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    sessionsSheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF0F5132' }
    };

    sessions.forEach(s => {
      sessionsSheet.addRow({
        date: new Date(s.date).toLocaleString(),
        customer: s.customer_name,
        type: s.session_type.replace('_', ' '),
        pricePaid: parseFloat(s.price_paid),
        totalCost: parseFloat(s.total_cost),
        debt: parseFloat(s.debt_amount),
        cups: parseInt(s.cups_used)
      });
    });

    // Worksheet 2: Expenses
    const expensesSheet = workbook.addWorksheet('Clinic Expenses');
    expensesSheet.columns = [
      { header: 'Expense Date', key: 'date', width: 25 },
      { header: 'Category', key: 'category', width: 18 },
      { header: 'Amount Paid', key: 'amount', width: 15 },
      { header: 'Description', key: 'description', width: 30 }
    ];

    expensesSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    expensesSheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF8E1D1D' }
    };

    expenses.forEach(e => {
      expensesSheet.addRow({
        date: new Date(e.date).toLocaleString(),
        category: e.category,
        amount: parseFloat(e.amount),
        description: e.description
      });
    });

    // Worksheet 3: Supply Restocks
    const purchaseSheet = workbook.addWorksheet('Supply Restocks');
    purchaseSheet.columns = [
      { header: 'Purchase Date', key: 'date', width: 25 },
      { header: 'Supply Name', key: 'name', width: 25 },
      { header: 'Quantity Purchased', key: 'qty', width: 18 },
      { header: 'Total Cost', key: 'cost', width: 15 },
      { header: 'Supplier Name', key: 'supplier', width: 25 },
      { header: 'Invoice Number', key: 'invoice', width: 20 }
    ];

    purchaseSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    purchaseSheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF2980B9' }
    };

    purchases.forEach(p => {
      purchaseSheet.addRow({
        date: new Date(p.date).toLocaleString(),
        name: p.item_name,
        qty: p.quantity,
        cost: parseFloat(p.total_cost),
        supplier: p.supplier,
        invoice: p.invoice_number
      });
    });

    await workbook.xlsx.write(stream);
  }
}

module.exports = new ExcelService();
