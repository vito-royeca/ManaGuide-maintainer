package com.manakit;

public class ManaKit {
    public enum Constants {
        ServerInfo("2020-03-21 10:25 UTC");

        private String value;

        Constants(String value) {
            this.value = value;
        }

        public String getValue() {
            return value;
        }
    }
}
