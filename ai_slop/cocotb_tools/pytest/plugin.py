"""
Shim pytest plugin module for pytest-cocotb when running against cocotb 2.0.

The real plugin lived at cocotb_tools.pytest.plugin in earlier releases, but
pytest-cocotb still imports that entrypoint. Providing this empty module keeps
pytest's plugin loading from failing; the actual test execution is driven
explicitly via cocotb_tools.runner in the test suite.
"""
