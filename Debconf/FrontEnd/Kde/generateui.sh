#! /bin/bash

#this is a hack around a bug in puic4 that it can't set the package correctly

set -e

puic4 WizardUi.ui  | sed 's/package Ui_DebconfWizard;/package Debconf::FrontEnd::Kde::Ui_DebconfWizard;/' > Ui_DebconfWizard.pm
