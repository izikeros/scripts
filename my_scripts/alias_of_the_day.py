#!/usr/bin/env python3
import random
from pathlib import Path


def get_indices_of_lines_starting_with_prefix(lines, prefix):
    """
    Returns the indices of lines starting with the given prefix.
    """
    indices = []
    for i, line in enumerate(lines):
        if line.startswith(prefix):
            indices.append(i)
    return indices


# return line preceding line with given indice if this preceding line is a comment
def get_comment_line_before_line(lines, indice):
    """
    Returns the line preceding the line with the given indice if this preceding line is a comment.
    """
    if indice == 0:
        return None
    else:
        line = lines[indice - 1]
        if line.startswith("#"):
            return line
        else:
            return ""


def read_aliases_file(filename=Path.home() / ".zsh_aliases"):
    """
    Reads the aliases file.
    """
    with open(filename) as f:
        lines = f.readlines()
    return lines


def extract_alias_name_from_line(line):
    """
    Returns the alias name from the given line.
    """
    return line.split("=")[0].strip().replace("alias ", "").strip()


def get_random_element_from_the_list(list):
    """
    Returns a random element from the given list.
    """
    return list[random.randint(0, len(list) - 1)]


if __name__ == "__main__":
    lines = read_aliases_file()
    alias_indices = get_indices_of_lines_starting_with_prefix(lines, "alias")
    sel_alias_indice = get_random_element_from_the_list(alias_indices)
    comment_text = get_comment_line_before_line(lines, sel_alias_indice)
    alias = lines[sel_alias_indice].strip()
    alias_name = extract_alias_name_from_line(alias)
    alias_name_length = len(alias_name)
    border = "-" * alias_name_length
    print(f"{border}\n{alias_name}\n{border}")
    print(comment_text.strip().lstrip("#").strip())
    print(alias)
