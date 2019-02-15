#!/usr/bin/env python3
# -------------------------------------------------------------------------------------------------
# <copyright file="trader.pyx" company="Invariance Pte">
#  Copyright (C) 2018-2019 Invariance Pte. All rights reserved.
#  The use of this source code is governed by the license as found in the LICENSE.md file.
#  http://www.invariance.com
# </copyright>
# -------------------------------------------------------------------------------------------------

# cython: language_level=3, boundscheck=False

import uuid

from cpython.datetime cimport datetime
from typing import List

from inv_trader.core.precondition cimport Precondition
from inv_trader.common.account cimport Account
from inv_trader.common.clock cimport LiveClock
from inv_trader.common.logger cimport Logger, LoggerAdapter
from inv_trader.common.data cimport DataClient
from inv_trader.common.execution cimport ExecutionClient
from inv_trader.portfolio.portfolio cimport Portfolio
from inv_trader.strategy cimport TradeStrategy


cdef class Trader:
    """
    Represents a trader for managing a portfolio of trade strategies.
    """

    def __init__(self,
                 str label,
                 list strategies,
                 DataClient data_client,
                 ExecutionClient exec_client,
                 Account account,
                 Portfolio portfolio,
                 Clock clock=LiveClock(),
                 Logger logger=None):
        """
        Initializes a new instance of the Trader class.

        :param label: The unique label for the trader.
        :param strategies: The initial list of strategies to manage (cannot be empty).
        :param logger: The logger for the trader (can be None).
        :raise ValueError: If the label is an invalid string.
        :raise ValueError: If the strategies list is empty.
        :raise ValueError: If the strategies list contains a type other than TradeStrategy.
        :raise ValueError: If the data client is None.
        :raise ValueError: If the exec client is None.
        :raise ValueError: If the clock is None.
        """
        Precondition.valid_string(label, 'label')
        Precondition.not_empty(strategies, 'strategies')
        Precondition.list_type(strategies, TradeStrategy, 'strategies')
        Precondition.not_none(data_client, 'data_client')
        Precondition.not_none(exec_client, 'exec_client')
        Precondition.not_none(clock, 'clock')

        self._clock = clock
        self.name = Label(self.__class__.__name__ + '-' + label)
        if logger is None:
            self._log = LoggerAdapter(f"{self.name.value}")
        else:
            self._log = LoggerAdapter(f"{self.name.value}", logger)
        self.id = GUID(uuid.uuid4())
        self._data_client = data_client
        self._exec_client = exec_client
        self.account = account
        self.portfolio = portfolio
        self.strategies = strategies
        self.started_datetimes = []  # type: List[datetime]
        self.stopped_datetimes = []  # type: List[datetime]

        self.portfolio.register_execution_client(self._exec_client)

        for strategy in strategies:
            self._data_client.register_strategy(strategy)
            self._exec_client.register_strategy(strategy)

    cpdef int strategy_count(self):
        """
        :return: The number of strategies held by the trader.
        """
        return len(self.strategies)

    cpdef void start(self):
        """
        Start the trader.
        """
        self.started_datetimes.append(self._clock.time_now())

        self._data_client.connect()
        self._exec_client.connect()

        self._data_client.update_all_instruments()

        for strategy in self.strategies:
            strategy.start()

    cpdef void stop(self):
        """
        Stop the trader.
        """
        self.stopped_datetimes.append(self._clock.time_now())

        for strategy in self.strategies:
            strategy.stop()

    cpdef void reset(self):
        """
        Reset the trader.
        """
        for strategy in self.strategies:
            strategy.reset()

    cpdef void dispose(self):
        """
        Dispose of the trader.
        """
        self._data_client.disconnect()
        self._exec_client.disconnect()
