from openpyxl import Workbook, load_workbook

from excel import Table, Cell


class Student(Table):
    __sheetname__ = '学生'

    姓名: Cell
    语文: Cell
    数学: Cell
    英语: Cell


def write_excel():
    wb = Workbook()

    ws = wb.active
    ws.title = Student.__sheetname__

    Student.write_full_heads(ws)

    table = Student(ws)
    
    row = table.new_row()
    row.姓名 = '张三'
    row.语文 = 90
    row.数学 = 80
    row.英语 = 70

    print(row.英语)

    wb.save('test.xlsx')


def read_excel():
    wb = load_workbook('test.xlsx')
    t = Student.select_sheet(wb)

    for row in t.iter_rows(min_row=2, values_only=True):
        print(row.姓名, row.数学, row.英语)


if __name__ == '__main__':
    read_excel()
