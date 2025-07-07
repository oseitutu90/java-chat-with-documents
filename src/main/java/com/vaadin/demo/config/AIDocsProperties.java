package com.vaadin.demo.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "ai.docs")
public class AIDocsProperties {

    private String location;
    private LangChain4j langchain4j;

    public static class LangChain4j {
        private OpenAI openAi;

        public static class OpenAI {
            private String apiKey;
            private String baseUrl;
            private String modelName;
            private String embeddingModelName;
            private String baseUrlChat;

            public String getBaseUrlChat() {
                return baseUrlChat;
            }

            public void setBaseUrlChat(String baseUrlChat) {
                this.baseUrlChat = baseUrlChat;
            }

            public String getApiKey() {
                return apiKey;
            }

            public void setApiKey(String apiKey) {
                this.apiKey = apiKey;
            }

            public String getEmbeddingModelName() {
                return embeddingModelName;
            }

            public void setEmbeddingModelName(String embeddingModelName) {
                this.embeddingModelName = embeddingModelName;
            }

            public String getBaseUrl() {
                return baseUrl;
            }

            public void setBaseUrl(String baseUrl) {
                this.baseUrl = baseUrl;
            }

            public String getModelName() {
                return modelName;
            }

            public void setModelName(String modelName) {
                this.modelName = modelName;
            }
        }

        public OpenAI getOpenAi() {
            return openAi;
        }

        public void setOpenAi(OpenAI openAi) {
            this.openAi = openAi;
        }
    }

    public LangChain4j getLangchain4j() {
        return langchain4j;
    }

    public void setLangchain4j(LangChain4j langchain4j) {
        this.langchain4j = langchain4j;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }
}
