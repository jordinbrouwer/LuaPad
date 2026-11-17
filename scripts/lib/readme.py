"""The release block in README.md (badges, latest release), which only belongs on GitHub."""
import re

START, END = "<!-- release:start -->", "<!-- release:end -->"
BLOCK = re.compile(rf"^{re.escape(START)}$.*?^{re.escape(END)}$\n?", re.M | re.S)


def without_block(text):
    return BLOCK.sub("", text)
