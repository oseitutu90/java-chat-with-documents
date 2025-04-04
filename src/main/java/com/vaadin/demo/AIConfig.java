package com.vaadin.demo;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.vaadin.demo.config.AIDocsProperties;
import com.vaadin.demo.config.MongoDbProperties;
import dev.langchain4j.data.document.loader.FileSystemDocumentLoader;
import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.memory.chat.ChatMemoryProvider;
import dev.langchain4j.memory.chat.MessageWindowChatMemory;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.chat.StreamingChatLanguageModel;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.model.ollama.OllamaEmbeddingModel;
import dev.langchain4j.model.ollama.OllamaStreamingChatModel;
import dev.langchain4j.rag.content.retriever.ContentRetriever;
import dev.langchain4j.rag.content.retriever.EmbeddingStoreContentRetriever;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.store.embedding.EmbeddingStore;
import dev.langchain4j.store.embedding.EmbeddingStoreIngestor;
import dev.langchain4j.store.embedding.mongodb.MongoDbEmbeddingStore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties({AIDocsProperties.class, MongoDbProperties.class})
public class AIConfig {

    private static final Logger log = LoggerFactory.getLogger(AIConfig.class);
    private final AIDocsProperties aiDocsProperties;
    private final MongoDbProperties mongoDbProperties;

    @Autowired
    public AIConfig(AIDocsProperties aiDocsProperties, MongoDbProperties mongoDbProperties) {
        this.aiDocsProperties = aiDocsProperties;
        this.mongoDbProperties = mongoDbProperties;
    }

    @Bean
    public MongoClient mongoClient() {
        return MongoClients.create(mongoDbProperties.getUri());
    }

    @Bean
    public EmbeddingStore<TextSegment> embeddingStore(MongoClient mongoClient) {
        return MongoDbEmbeddingStore.builder()
                .fromClient(mongoClient)
                .databaseName(mongoDbProperties.getDatabase())
                .collectionName(mongoDbProperties.getCollection())
                .indexName(mongoDbProperties.getIndexName())
                .createIndex(true)
                .build();
    }

    @Bean
    public EmbeddingModel embeddingModel() {
        return OllamaEmbeddingModel.builder()
                .baseUrl(aiDocsProperties.getLangchain4j().getOpenAi().getBaseUrl())
                .modelName(aiDocsProperties.getLangchain4j().getOpenAi().getEmbeddingModelName())
                .build();
    }


    @Bean
    public ApplicationRunner docImporter(EmbeddingStore<TextSegment> embeddingStore, EmbeddingModel embeddingModel) {
        return args -> {
            var docsLocation = aiDocsProperties.getLocation();
            if (docsLocation == null || docsLocation.isEmpty()) {
                log.error("No document location specified, configure 'ai.docs.location'");
                return;
            }

            log.info("Importing documents from {}", docsLocation);
            var docs = FileSystemDocumentLoader.loadDocuments(docsLocation);

            EmbeddingStoreIngestor.builder()
                    .embeddingModel(embeddingModel)
                    .embeddingStore(embeddingStore)
                    .build()
                    .ingest(docs);

            var response = embeddingModel.embed("test string");
            log.info("Embedding dimension: {}", response.content().dimension());
            log.info("Imported {} documents", docs.size());
        };
    }

    @Bean
    public StreamingChatLanguageModel streamingChatLanguageModel() {
        return OllamaStreamingChatModel.builder()
                .baseUrl(aiDocsProperties.getLangchain4j().getOpenAi().getBaseUrl())
                .modelName(aiDocsProperties.getLangchain4j().getOpenAi().getModelName())
                .build();
    }

    @Bean
    public ContentRetriever contentRetriever(EmbeddingStore<TextSegment> embeddingStore, EmbeddingModel embeddingModel) {
        return EmbeddingStoreContentRetriever.builder()
                .embeddingStore(embeddingStore)
                .embeddingModel(embeddingModel)
                .build();
    }
    @Bean
    public ChatMemoryProvider chatMemoryProvider() {
        return chatId -> MessageWindowChatMemory.withMaxMessages(30);
    }

}
