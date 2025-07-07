import com.vaadin.demo.AIConfig;
import com.vaadin.demo.config.AIDocsProperties;
import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.memory.chat.MessageWindowChatMemory;
import dev.langchain4j.memory.chat.ChatMemoryProvider;
import dev.langchain4j.model.chat.StreamingChatLanguageModel;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.store.embedding.EmbeddingStore;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class AIConfigTest {
    @Test
    void beansCreated() {
        AIDocsProperties props = new AIDocsProperties();
        AIDocsProperties.LangChain4j lc = new AIDocsProperties.LangChain4j();
        AIDocsProperties.LangChain4j.OpenAI open = new AIDocsProperties.LangChain4j.OpenAI();
        open.setBaseUrl("http://host");
        open.setModelName("model");
        open.setEmbeddingModelName("embed");
        lc.setOpenAi(open);
        props.setLangchain4j(lc);

        AIConfig config = new AIConfig(props);
        EmbeddingStore<TextSegment> embeddingStore = config.embeddingStore();
        assertNotNull(embeddingStore);
        EmbeddingModel embeddingModel = config.embeddingModel();
        assertNotNull(embeddingModel);
        ChatMemoryProvider provider = config.chatMemoryProvider();
        MessageWindowChatMemory memory = (MessageWindowChatMemory) provider.get("id");
        assertNotNull(memory);
        StreamingChatLanguageModel model = config.streamingChatLanguageModel();
        assertNotNull(model);
    }
}
