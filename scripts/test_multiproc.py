#!/usr/bin/env python3
"""Lightweight test to validate prometheus_client multiprocess aggregation and cleanup."""
import os
import sys
import tempfile
import subprocess
import time
from pathlib import Path

PY = sys.executable

CHILD_CODE = r"""
import os,sys
os.environ['PROMETHEUS_MULTIPROC_DIR'] = sys.argv[1]
from prometheus_client import Counter
c = Counter('test_counter_multiproc_total', 'test counter')
# increment different values to ensure sum
c.inc(2 if int(sys.argv[2]) == 1 else 3)
# ensure file is written
print('child done')
"""


def run_child(tmpdir, n):
    cmd = [PY, '-c', CHILD_CODE, tmpdir, str(n)]
    subprocess.run(cmd, check=True)


def read_aggregated(tmpdir: str) -> str:
    os.environ['PROMETHEUS_MULTIPROC_DIR'] = tmpdir
    from prometheus_client import CollectorRegistry, generate_latest, multiprocess
    registry = CollectorRegistry()
    multiprocess.MultiProcessCollector(registry)
    out = generate_latest(registry).decode()
    return out


def main():
    tmp = tempfile.mkdtemp(prefix='prom_mproc_test_')
    print('tmpdir:', tmp)

    # run two child processes that write multiproc files
    run_child(tmp, 1)
    run_child(tmp, 2)

    # give a moment for files to flush
    time.sleep(0.5)

    metrics = read_aggregated(tmp)
    print(metrics)

    # Expect total 5 (2+3)
    if 'test_counter_multiproc_total' not in metrics:
        print('FAIL: metric not found')
        sys.exit(2)
    if '5.0' not in metrics and '5' not in metrics:
        print('FAIL: expected aggregated value 5, got:')
        print(metrics)
        sys.exit(3)

    # Create a dummy file to test cleanup script
    dummy = Path(tmp) / 'dummy_file'
    dummy.write_text('xyz')
    assert dummy.exists()

    # Run cleanup script
    script = Path(__file__).parent / 'clean_multiproc_dir.sh'
    subprocess.run([str(script)], check=True, env={**os.environ, 'PROMETHEUS_MULTIPROC_DIR': tmp})

    # check files cleaned (only directories may remain)
    remaining = list(Path(tmp).glob('*'))
    if remaining:
        print('FAIL: cleanup did not remove files, remaining:', remaining)
        sys.exit(4)

    print('OK')


if __name__ == '__main__':
    main()
