#!/bin/bash

kill $(lsof -t -i @localhost:8585)