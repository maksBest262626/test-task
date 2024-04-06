<?php

declare(strict_types=1);

namespace App\ValueObject;

use App\Exception\EmailIsNotValidException;

final class Email implements \Stringable
{
    private readonly string $email;

    /** @throws EmailIsNotValidException */
    private function __construct(string $email) {
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new EmailIsNotValidException(EmailIsNotValidException::TRANSLATOR_PHRASE);
        }
        
        $this->email = $email;
    }

    /** @throws EmailIsNotValidException */
    public static function createFromString(string $email): self
    {
        return new self($email);
    }
    
    public function value(): string {
        return $this->email;
    }
    
    public function __toString(): string {
        return $this->email;
    }
}