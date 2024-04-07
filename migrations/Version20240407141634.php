<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20240407141634 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '[add password field]';
    }

    public function up(Schema $schema): void
    {
        $this->addSql('ALTER TABLE users ADD password VARCHAR(255) NOT NULL');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('ALTER TABLE users DROP password');
    }
}
