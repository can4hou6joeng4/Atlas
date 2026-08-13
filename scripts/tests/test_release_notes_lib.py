import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from release_notes_lib import clean_body_items


class CleanBodyItemsTests(unittest.TestCase):
    def test_indented_continuation_stays_with_bullet(self) -> None:
        body = (
            "- .swiftlint.yml: 基于实测调优的务实配置,\n"
            "  关闭与既有风格冲突的规则,阈值设为合理上限。\n"
            "- .github/workflows/lint.yml: push/PR 触发,\n"
            "  pin swiftlint 0.63.3 防规则漂移。"
        )
        self.assertEqual(
            clean_body_items(body),
            [
                ".swiftlint.yml: 基于实测调优的务实配置, 关闭与既有风格冲突的规则,阈值设为合理上限。",
                ".github/workflows/lint.yml: push/PR 触发, pin swiftlint 0.63.3 防规则漂移。",
            ],
        )

    def test_plain_bullets_unchanged(self) -> None:
        self.assertEqual(
            clean_body_items("- 修复A\n- 修复B\n- 修复C"),
            ["修复A", "修复B", "修复C"],
        )

    def test_paragraph_lines_merge(self) -> None:
        self.assertEqual(
            clean_body_items("这是第一行\n这是第二行"),
            ["这是第一行 这是第二行"],
        )

    def test_blank_line_separates_bullet_from_paragraph(self) -> None:
        body = "- 项目X: 说明,\n  续行补充。\n\n独立段落句。"
        self.assertEqual(
            clean_body_items(body),
            ["项目X: 说明, 续行补充。", "独立段落句。"],
        )

    def test_duplicate_items_deduped(self) -> None:
        self.assertEqual(clean_body_items("- 同句\n- 同句"), ["同句"])

    def test_heading_then_bullet_with_continuation(self) -> None:
        self.assertEqual(
            clean_body_items("变更:\n- 改了X\n  续行Y"),
            ["改了X 续行Y"],
        )

    def test_trailer_lines_dropped(self) -> None:
        body = "- 真实变更\n  续行。\n\nSigned-off-by: Someone <s@example.com>"
        self.assertEqual(clean_body_items(body), ["真实变更 续行。"])


if __name__ == "__main__":
    unittest.main()
