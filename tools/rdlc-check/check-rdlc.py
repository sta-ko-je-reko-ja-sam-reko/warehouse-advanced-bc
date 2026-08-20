"""Check every RDLC layout in app/ against the AL report it belongs to.

Verified against alc 17.0.34.45391, the compiler catches some of this and not the rest:

  * malformed XML  -> error AL0444, caught
  * a missing file -> no error; alc silently *generates* a default layout in its place
  * Fields!DoesNotExist.Value in a valid layout -> not caught, renders blank

So the build catches a layout that is broken and misses one that is merely wrong, which is
the more likely mistake and the harder one to see.

This script closes as much of that gap as static checking can:

  * the layout is well-formed XML and is really a Report
  * it declares a dataset named DataSet_Result, which is what Business Central binds
  * every <Field> it declares is a column on the AL report, or the <Column>Format companion
    the compiler generates for a formatted column
  * every Fields!X.Value in an expression is a declared field
  * every Parameters!X.Value is either a column caption the report actually publishes
    (a column with IncludeCaption = true) or a label the report declares
  * textbox names are unique, which RDLC requires and nothing else checks

What it cannot tell you is whether the thing renders, or whether it looks like anything a
warehouse would want to hold. That needs a container and a pair of eyes.

Run from the repository root:  python tools/rdlc-check/check-rdlc.py
"""

import io
import os
import re
import sys
import xml.etree.ElementTree as ET

RDL_NS = '{http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition}'
APP = 'app'

RE_REPORT = re.compile(r'^\s*report\s+(\d+)\s+"([^"]+)"', re.M)
RE_LAYOUT = re.compile(r"RDLCLayout\s*=\s*'([^']+)'")
RE_COLUMN = re.compile(r'column\(\s*(\w+)\s*;', re.M)
RE_LABELS = re.compile(r'^\s{4}labels\s*$\s*^\s{4}\{(.*?)^\s{4}\}', re.M | re.S)
RE_LABEL_NAME = re.compile(r'^\s*(\w+)\s*=', re.M)

RE_FIELD_REF = re.compile(r'Fields!(\w+)\.Value')
RE_PARAM_REF = re.compile(r'Parameters!(\w+)\.Value')


def al_reports(root):
    for base, _dirs, files in os.walk(os.path.join(root, 'src')):
        for name in files:
            if name.endswith('.Report.al'):
                yield os.path.join(base, name)


def parse_al(path):
    text = io.open(path, encoding='utf-8-sig').read()
    m = RE_REPORT.search(text)
    if not m:
        return None
    layout = RE_LAYOUT.search(text)

    columns = RE_COLUMN.findall(text)
    captioned = set()
    for name in columns:
        start = text.index('column(%s;' % name)
        end = text.find('column(', start + 1)
        body = text[start:end if end != -1 else len(text)]
        if 'IncludeCaption = true' in body:
            captioned.add(name + 'Caption')

    labels = set()
    lm = RE_LABELS.search(text)
    if lm:
        labels = set(RE_LABEL_NAME.findall(lm.group(1)))

    return {
        'file': path,
        'name': m.group(2),
        'layout': layout.group(1) if layout else None,
        'columns': set(columns),
        'captions': captioned,
        'labels': labels,
    }


def check(report, problems):
    rel = report['layout']
    if not rel:
        return
    layout_path = os.path.normpath(os.path.join(APP, rel.lstrip('./')))

    def bad(msg):
        problems.append('%s (%s): %s' % (report['name'], rel, msg))

    if not os.path.isfile(layout_path):
        bad('the layout file does not exist')
        return

    raw = io.open(layout_path, encoding='utf-8-sig').read()
    try:
        tree = ET.fromstring(raw)
    except ET.ParseError as exc:
        bad('not well-formed XML — %s' % exc)
        return

    if not tree.tag.endswith('}Report') and tree.tag != 'Report':
        bad('the root element is %s, not Report' % tree.tag)
        return

    datasets = [d.get('Name') for d in tree.iter(RDL_NS + 'DataSet')]
    if 'DataSet_Result' not in datasets:
        bad('no dataset named DataSet_Result; found %s' % (datasets or 'none'))

    declared = {f.get('Name') for f in tree.iter(RDL_NS + 'Field')}
    # alc syncs the report's dataset into the layout when it builds, and adds a companion
    # <Column>Format field for every formatted column. Those are the compiler's, not ours.
    known_fields = report['columns'] | {c + 'Format' for c in report['columns']}
    unknown = sorted(declared - known_fields)
    if unknown:
        bad('declares fields the report has no column for: %s' % ', '.join(unknown))

    used_fields = set(RE_FIELD_REF.findall(raw))
    undeclared = sorted(used_fields - declared)
    if undeclared:
        bad('uses fields it never declares: %s' % ', '.join(undeclared))

    known_params = report['captions'] | report['labels']
    used_params = set(RE_PARAM_REF.findall(raw))
    unknown_params = sorted(used_params - known_params)
    if unknown_params:
        bad('uses parameters the report does not publish: %s' % ', '.join(unknown_params))

    names = [t.get('Name') for t in tree.iter(RDL_NS + 'Textbox')]
    duplicates = sorted({n for n in names if names.count(n) > 1})
    if duplicates:
        bad('has textboxes sharing a name: %s' % ', '.join(duplicates))


def main():
    problems = []
    checked = 0
    for path in al_reports(APP):
        report = parse_al(path)
        if not report:
            continue
        if not report['layout']:
            print('  no layout   %s' % report['name'])
            continue
        check(report, problems)
        checked += 1
        print('  checked     %s' % report['name'])

    print('')
    if problems:
        print('%d problem(s):' % len(problems))
        for p in problems:
            print('  - %s' % p)
        return 1

    print('%d layout(s) check out. Still unproven: whether any of them renders.' % checked)
    return 0


if __name__ == '__main__':
    sys.exit(main())
