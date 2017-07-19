"""  shakedown tests to test chronos on DCOS
"""

import shakedown
import datetime
import json
import time

from distutils.version import LooseVersion

from dcos import http, cosmos, packagemanager
from dcos.errors import DCOSException, DCOSHTTPException


def test_install_chronos():
    """ installs the latest version of chronos
    """
    shakedown.install_package_and_wait('chronos')
    assert shakedown.package_installed('chronos'), 'Package failed to install'

    stdout, stderr, return_code = shakedown.run_dcos_command('package list')
    assert "chronos" in stdout

    uninstall()


def test_job():

    shakedown.install_package_and_wait('chronos')

    # 0 tasks
    tasks = shakedown.get_service('chronos')['completed_tasks']
    assert len(tasks) == 0

    if is_before_version("3.0"):
        url = shakedown.dcos_service_url('chronos/scheduler/jobs')
    else:
        url = shakedown.dcos_service_url('chronos/v1/scheduler/jobs')

    jobs = http.get(url).json()
    assert len(jobs) == 0

    # add a job
    if is_before_version("3.0"):
        url = shakedown.dcos_service_url('chronos/scheduler/iso8601')
    else:
        url = shakedown.dcos_service_url('chronos/v1/scheduler/iso8601')

    data = default_job()
    headers = {'Content-Type': 'application/json'}
    http.post(url, data=data, headers=headers)

    # give it a couple of seconds
    time.sleep(5)

    tasks = shakedown.get_service('chronos')['completed_tasks']
    assert len(tasks) > 0

    id = tasks[0]['id']
    status, out = shakedown.run_command_on_master('date')
    sdate = out[:10]
    stdout, stderr, return_code = shakedown.run_dcos_command('task log --completed {}'.format(id))
    assert sdate in stdout


def todays_iso8601(repeat='02S'):
    """ repeat is every 2 secs
    """
    today = datetime.date.today()
    sdate = today.strftime("%Y-%m-%d")
    return "R/{}/PT{}".format(sdate, repeat)


def default_job(job_name='Date'):
    job_schedule = todays_iso8601()
    return json.dumps({"name": job_name, "schedule": job_schedule, "command": "/bin/date"})


def teardown_module(module):
    uninstall()


def uninstall():
        shakedown.uninstall_package_and_wait('chronos')
        shakedown.delete_zk_node('/chronos')


def is_before_version(version="3.0.0"):
    return _version(_chronos_package_version()) < _version(version)


def _version(version):
    return LooseVersion(version)


def _chronos_package_version():
    pkg = _get_package_manager().get_package_version('chronos', None)
    if _get_packaging_version(pkg) >= _version("4.0"):
        return pkg.__dict__['_package_json']['package']['version']
    else:
        return pkg.__dict__['_package_json']['version']


def _get_packaging_version(pkg):
    package_json = pkg.__dict__['_package_json']
    if 'package' in package_json:
        return package_json['package']['packagingVersion']
    else:
        return package_json['packagingVersion']


def _get_package_manager():
    """ Get an instance of Cosmos with the correct URL.

        # :return: Cosmos instance
        :rtype: packagemanager.P:return: Cosmos instanceackageManager
    """
    return packagemanager.PackageManager(cosmos.get_cosmos_url())
