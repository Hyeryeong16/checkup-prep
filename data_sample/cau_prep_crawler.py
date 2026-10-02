"""중앙대학교병원 검사 전 유의사항 원문 수집 예시.

설치:
    python -m pip install playwright beautifulsoup4
    python -m playwright install chromium

실행:
    python data_sample/cau_prep_crawler.py

결과: 스크립트와 같은 폴더에 cau_prep_raw.txt를 저장합니다.
JSON 구조화는 이 코드에 포함되지 않으며, 수집 후 Claude를 활용해
별도로 진행했습니다.
"""

import asyncio
from pathlib import Path

from bs4 import BeautifulSoup
from playwright.async_api import async_playwright


SOURCE_URL = "https://ch.cauhs.or.kr/home/conts/105001032005000.do"
TXT_PATH = Path(__file__).resolve().parent / "cau_prep_raw.txt"


async def scrape_cau_prep():
    async with async_playwright() as p:
        # 화면 없이 백그라운드에서 Chromium을 실행합니다.
        browser = await p.chromium.launch(headless=True)
        try:
            context = await browser.new_context(
                user_agent=(
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) "
                    "Chrome/120.0.0.0 Safari/537.36"
                )
            )
            page = await context.new_page()
            print(f"[{SOURCE_URL}] 중앙대학교병원 검사 전 유의사항 페이지 접속 중...")

            response = await page.goto(
                SOURCE_URL, wait_until="networkidle", timeout=30000
            )
            if response is None or not response.ok:
                status = response.status if response else "응답 없음"
                raise RuntimeError(f"페이지 요청 실패: {status}")

            # 동적 콘텐츠 렌더링을 기다립니다.
            await page.wait_for_timeout(2000)
            html_content = await page.content()

            # 불필요한 레이아웃 요소를 제거합니다.
            soup = BeautifulSoup(html_content, "html.parser")
            for tag in soup(["script", "style", "header", "footer", "nav", "iframe"]):
                tag.decompose()

            # 페이지 텍스트를 추출하고 TXT 파일로 저장합니다.
            extracted_text = soup.get_text(separator="\n", strip=True)
            if not extracted_text:
                raise ValueError("페이지에서 텍스트를 추출하지 못했습니다.")
            TXT_PATH.write_text(extracted_text + "\n", encoding="utf-8")

            print(f"수집 완료: {TXT_PATH.name}")
            print("\n추출된 텍스트 미리보기 (상위 300자)")
            print(extracted_text[:300])
        finally:
            await browser.close()


if __name__ == "__main__":
    try:
        asyncio.run(scrape_cau_prep())
    except Exception as e:
        raise SystemExit(f"크롤링 중 오류 발생: {e}") from e
