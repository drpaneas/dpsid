# SUSE's openQA tests
#
# Copyright © 2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Test the version of the containers versus the images RPMs
# Maintainer: Panos Georgiadis <pgeorgiadis@suse.com>
# Tags: bnc#1031480

use strict;
use base "opensusebasetest";
use testapi;
use utils 'is_caasp';
use caasp;

sub run {
    assert_script_run "curl -O " . data_url('console/test_containers_image_rpm_check.sh');
    assert_script_run 'chmod +x test_containers_image_rpm_check.sh';
    assert_script_run './test_containers_image_rpm_check.sh';
}
1;
# vim: set sw=4 et:
