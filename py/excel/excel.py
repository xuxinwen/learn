from typing import Sequence, List, Iterator, Self
import copy

from openpyxl.worksheet.worksheet import Worksheet
from openpyxl.cell.cell import Cell
from openpyxl.utils import column_index_from_string
from openpyxl import Workbook


def __format__(self, __format_spec: str) -> str:
    if not __format_spec:
        return self.coordinate
    return super().__format__(__format_spec)  # suppress pylance error on this line


Cell.__format__ = __format__


class Column(str):
    '''
    代表 excel 表中的列名
    '''
    attr_name: str
    fix_index: int

    def __new__(
        cls, val='', fix_index=None
    ):
        obj = str.__new__(cls, val)
        obj.fix_index = fix_index
        return obj

    def __set_name__(self, cls, name):
        self.attr_name = name

    def __get__(self, obj, cls):
        if obj is None:
            return self

        index = obj.__dict__.get(self.attr_name)
        if index is None:
            raise AttributeError(f'{self.attr_name} 列名不存在，可用的列名有 {obj.columns}')

        if obj.row is None:
            return index
        
        cell = obj.row[index]
        return cell

    def __set__(self, obj, value):
        if obj.row is None:
            raise AttributeError('不能给未绑定的对象赋值')

        index = obj.__dict__.get(self.attr_name)
        if index is None:
            raise AttributeError(f'{self.attr_name} 列名不存在，可用的列名有 {obj.columns}')

        cell = obj.row[index]

        if isinstance(cell, Cell):
            cell.value = value
        else:
            obj.row[index] = value

    def __delete__(self, instance):
        pass


class Index(int):
    column: Column

    def __new__(cls, val, col=None):
        obj = int.__new__(cls, val)
        obj.column = col
        return obj


class TableType(type):
    def __new__(cls, name, bases, attrs: dict):
        if not bases:
            return type.__new__(cls, name, bases, attrs)

        # 将 `__annotations__` 中的字段转换成 `class` 属性
        # 每个属性的值是 `Column` 类型的实例
        for attr, _ in attrs['__annotations__'].items():
            if attr.startswith('__'):
                continue

            col: Column = attrs.pop(attr, None)
            if col is None:
                attrs[attr] = Column(val=attr)
            else:
                if not col:
                    new_col = Column(val=attr)
                    new_col.__dict__.update(col.__dict__)
                    attrs[attr] = new_col
                else:
                    attrs[attr] = col

        return type.__new__(cls, name, bases, attrs)


class Table(metaclass=TableType):
    __sheetname__: str = ''

    def __init__(
        self, sheet: Worksheet, header_row=1, header_all_exist=False,
    ) -> None:
        self.sheet = sheet

        self.set_fix_index()
        self.locate_header(header_row)
        self.first_row_idx = header_row + 1

        if header_all_exist:
            notfound_headers = self.notfound_headers
            if notfound_headers:
                raise ValueError(f'{notfound_headers} 没有匹配')
        self.row = None

    def copy(self):
        return copy.copy(self)

    def set_fix_index(self):
        for attr, col in self.__class__.__dict__.items():
            if not isinstance(col, Column):
                continue
            
            idx = col.fix_index

            if idx is None:
                continue
            
            if isinstance(idx, str):
                idx = column_index_from_string(idx)

            self.__dict__[attr] = Index(idx, col=col)

    @property
    def notfound_headers(self) -> List[str]:
        rst = []
        for attr, col in self.__class__.__dict__.items():
            if not isinstance(col, Column):
                continue
            
            if attr in self.__dict__:
                continue

            rst.append(attr)
        return rst

    def locate_header(self, header_row):
        heads = [c.value for c in self.sheet[header_row]]

        for attr, col in self.__class__.__dict__.items():
            if not isinstance(col, Column):
                continue
            
            if col.fix_index is not None:
                continue

            try:
                self.__dict__[attr] = Index(heads.index(col), col=col)
            except ValueError:
                pass

    @property
    def current_row_idx(self):
        return self.sheet._current_row

    def iter_rows(
            self, min_row=None, max_row=None, min_col=None, max_col=None, values_only=False
        ) -> Iterator[Self]:
        min_row = min_row or self.first_row_idx

        for row in self.sheet.iter_rows(
            min_row=min_row, max_row=max_row, min_col=min_col, max_col=max_col, values_only=values_only
        ):
            obj = self.copy().bind_row(row)
            yield obj

    @property
    def columns(self) -> Sequence[Column]:
        '''
        获取当前sheet有的列，从实例对象中获取
        '''

        cols = []

        for i in self.__dict__.values():
            if not isinstance(i, Index):
                continue

            cols.append(
                i.column
            )
        return cols

    @property
    def columns_count(self) -> int:
        return len(self.indexes)

    def new_orphan_row(self, empty=None) -> list:
        '''
        根据当前列数量创建一行，该行还没有添加到表中
        '''
        return [empty] * self.columns_count

    def new_row(self, empty=None) -> Self:
        row = self.new_orphan_row(empty)
        self.sheet.append(row)
        row = self.sheet[self.current_row_idx]
        t_row = self.copy()
        t_row.bind_row(row)
        return t_row

    @classmethod
    def get_full_columns(cls) -> Sequence[str]:
        cols = []
        for _, val in cls.__dict__.items():
            if not isinstance(val, Column):
                continue
            cols.append(val)
        return cols

    @property
    def indexes(self) -> Sequence[int]:
        rst = []
        for v in self.__dict__.values():
            if not isinstance(v, Index):
                continue
            rst.append(v)
        return rst

    @classmethod
    def write_full_heads(cls, sheet: Worksheet):
        '''
        将该 model 上定义的字段全部写入到 sheet
        '''
        sheet.append(cls.get_full_columns())

    def bind_row(self, row):
        self.row = row
        return self

    def unbind_row(self):
        self.row = None

    @classmethod
    def select_sheet(cls, wb: Workbook) -> Self:
        ws = wb[cls.__sheetname__]
        return cls(ws)
