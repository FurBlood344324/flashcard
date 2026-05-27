import factory
from faker import Faker

from models import Deck, Flashcard

fake = Faker("tr_TR")


class DeckFactory(factory.Factory):
    class Meta:
        model = Deck

    name = factory.Sequence(lambda n: f"deck-{n}-{fake.word()}")
    description = factory.LazyFunction(lambda: fake.sentence(nb_words=6))
    user_id = 1

    @classmethod
    def payload(cls, **overrides: object) -> dict[str, object]:
        deck = cls.build(**overrides)
        return {"name": deck.name, "description": deck.description}


class FlashcardFactory(factory.Factory):
    class Meta:
        model = Flashcard

    deck_id = 1
    front = factory.LazyFunction(lambda: f"Soru: {fake.sentence(nb_words=5)}")
    back = factory.LazyFunction(lambda: f"Cevap: {fake.sentence(nb_words=7)}")
    difficulty = "new"
    review_count = 0
    interval_days = 0.0

    @classmethod
    def payload(cls, **overrides: object) -> dict[str, object]:
        flashcard = cls.build(**overrides)
        return {"front": flashcard.front, "back": flashcard.back}
